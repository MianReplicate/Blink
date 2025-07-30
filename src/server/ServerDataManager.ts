import Object from "@rbxts/object-utils";
import { HttpService, Players, Workspace } from "@rbxts/services";
import {
	ActiveDataObjects,
	AddTickable,
	DataObject,
	Debug,
	EditFunction,
	Holdable,
	HoldableProxy,
	Keyable,
	ReplicatedDataObject,
	ReplicatedDataObjects,
	ReplicateToPlayer,
	Valuable,
} from "shared/DataManager";

type OwnerCriterias = Array<Player | string>;

const PendingGCFlush = new Array<DataObject<Holdable>>();

export class ServerDataObject<T extends Holdable> extends DataObject<T> {
	private keyReplicators: Map<Keyable, OwnerCriterias>;
	private keyEditors: Map<Keyable, OwnerCriterias>;
	private dirtyKeys: Set<Keyable>;
	private uuid: string | undefined;

	protected constructor(holder: T) {
		super(holder);
		this.keyReplicators = new Map();
		this.keyEditors = new Map();
		this.dirtyKeys = new Set();

		if (typeIs(holder, "Instance")) {
			this.uuid = holder.GetAttribute("uuid") as string;
		}
	}

	public static construct<T extends Holdable>(holder: T): ServerDataObject<T> {
		if (ActiveDataObjects.has(holder)) {
			return ActiveDataObjects.get(holder) as ServerDataObject<T>;
		}
		return new ServerDataObject<T>(holder);
	}

	public static waitFor<T extends Holdable>(holder: T, secondsToWait: number): ServerDataObject<T> | undefined {
		const dataObject = super.waitFor(holder, secondsToWait);
		if (dataObject === undefined) return dataObject;
		return dataObject as ServerDataObject<T>;
	}

	public override setValue(key: Keyable, value: Valuable): void {
		if (this.isPendingGC()) return;
		super.setValue(key, value);
		if (this.keyReplicators.has(key)) this.dirtyKeys.add(key);
		// this.replicateToAll(key);
	}

	public override destroy(): void {
		super.destroy();
		this.uuid = undefined;
		PendingGCFlush.push(this);
	}

	// private replicateToAll(key: Keyable) {
	// 	if (this.isPendingGC()) return;
	// 	this.keyReplicators.get(key)?.forEach((use) => {
	// 		if (typeIs(use, "string")) {
	// 			print("Tag value!!: " + use);

	// 			Players.GetPlayers().forEach((player) => this.replicate(key, player));
	// 		} else {
	// 			print("is player we're replicating to: " + use.DisplayName);
	// 			this.replicate(key, use);
	// 		}
	// 	});
	// }

	// private replicate(key: Keyable, player: Player) {
	// 	if (this.isPendingGC()) return;
	// 	const value = this.getValue(key);
	// 	const holder = this.getHolder();
	// 	ReplicateToPlayer(player, { holder, key, value });
	// }

	private static IsAOwner(player: Player, ownerCriterias: OwnerCriterias): boolean {
		return (
			ownerCriterias !== undefined &&
			!ownerCriterias
				?.filter(
					(replicator) =>
						replicator === player || (typeIs(replicator, "string") && player.HasTag(replicator)),
				)
				.isEmpty()
		);
	}

	private static GetOwnersFor(players: Array<Player>, ownerCriterias: OwnerCriterias): Array<Player> {
		return players.filter((player) => ServerDataObject.IsAOwner(player, ownerCriterias));
	}

	/**
	 * Flushes all dirty keys and replicates them to all valid players. This should not be run manually as it should already be handled in the central loop.
	 */
	private flush(): Map<Player, Map<Keyable, Valuable>> | undefined {
		if (this.isPendingGC() || this.dirtyKeys.isEmpty()) return undefined;

		const playerStorageMap = new Map<Player, Map<Keyable, Valuable>>();
		const players = Players.GetPlayers();

		this.dirtyKeys.forEach((key) => {
			const criterias = this.keyReplicators.get(key) as OwnerCriterias;
			const matchingPlayers = ServerDataObject.GetOwnersFor(players, criterias);

			let value = this.getValue(key);
			if (typeIs(value, "Instance")) value = value.GetAttribute("uuid") as string;

			matchingPlayers.forEach((player) => {
				let storage = playerStorageMap.get(player);
				if (!storage) {
					storage = new Map();
					playerStorageMap.set(player, storage);
				}
				storage.set(key, value);
			});
		});

		// const uuid = this.uuid;
		// const holderProxy: HoldableProxy = { holder, uuid };
		// playerStorageMap.forEach((storage, player) => ReplicateToPlayer(player, { holderProxy, storage }));

		this.dirtyKeys.clear();

		return playerStorageMap;
	}

	public static flushAll() {
		const playerToDataObjects = new Map<Player, ReplicatedDataObjects>();

		ActiveDataObjects.forEach((dataObject) => {
			if (dataObject instanceof ServerDataObject) {
				const playerStorageMap = dataObject.flush();
				playerStorageMap?.forEach((storage, player) => {
					let dataObjects = playerToDataObjects.get(player);
					if (dataObjects === undefined) {
						dataObjects = new Array();
						playerToDataObjects.set(player, dataObjects);
					}

					const holder = dataObject.getHolder();
					const uuid = dataObject.uuid;
					const holderProxy: HoldableProxy = { holder, uuid };
					dataObjects.push({ holderProxy, pendingGC: false, storage });
				});
			}
		});

		PendingGCFlush.forEach((dataObject) => {
			if (dataObject instanceof ServerDataObject) {
				const holder = dataObject.getHolder();
				const uuid = dataObject.uuid;
				const holderProxy: HoldableProxy = { holder, uuid };
				const object: ReplicatedDataObject = { holderProxy, pendingGC: true, storage: undefined };

				Players.GetPlayers().forEach((player) => {
					let dataObjects = playerToDataObjects.get(player);
					if (dataObjects === undefined) {
						dataObjects = new Array();
						playerToDataObjects.set(player, dataObjects);
					}
					dataObjects.push(object);
				});
			}
		});
		PendingGCFlush.clear();

		if (playerToDataObjects.size() > 0) {
			Debug("Flushing", playerToDataObjects);

			playerToDataObjects.forEach((objects, player) => ReplicateToPlayer(player, objects));
		}
	}

	/**
	 * Used to replicate to new joining players. This is already handled by an event.
	 * @param player The player to replicate to
	 * @returns What the user was replicated
	 */
	public static syncAllForNewPlayer(player: Player) {
		const objects = new Array<ReplicatedDataObject>();

		ActiveDataObjects.forEach((dataObject, holder) => {
			if (dataObject instanceof ServerDataObject) {
				const storage: Map<Keyable, Valuable> = new Map();

				dataObject.keyReplicators.forEach((replicatables, key) => {
					if (
						!replicatables
							.filter((value) => value === player || (typeIs(value, "string") && player.HasTag(value)))
							.isEmpty()
					) {
						storage.set(key, dataObject.getValue(key));
					}
				});

				const uuid = dataObject.uuid;
				const holderProxy: HoldableProxy = { holder, uuid };
				const replicatedDataObject: ReplicatedDataObject = { holderProxy, pendingGC: false, storage };
				objects.push(replicatedDataObject);
			}
		});

		ReplicateToPlayer(player, objects);

		Debug("Syncing", objects, "to", player);
	}

	/**
	 * The criteria needed for a player to pass for a key to replicate to
	 * @param key The key to replicate
	 * @param owners The owners for this key
	 */
	public setReplicateCriteriaForKey(key: Keyable, owners: OwnerCriterias) {
		if (this.isPendingGC()) return;
		this.keyReplicators.set(key, owners);
		this.dirtyKeys.add(key);
	}

	/**
	 * The criteria needed for a player to pass for the specified keys to replicate to
	 * @param keys Keys to replicate
	 * @param owners The owners for this key
	 */
	public setReplicateCriteriaForKeys(keys: Array<Keyable>, owners: OwnerCriterias) {
		if (this.isPendingGC()) return;
		keys.forEach((key) => this.setReplicateCriteriaForKey(key, owners));
	}

	/**
	 * The criteria needed for a player to pass for a key to be editable
	 * @param key The key to edit
	 * @param owners The owners for this key
	 */
	public setEditorCriteriaForKey(key: Keyable, owners: OwnerCriterias) {
		if (this.isPendingGC()) return;
		this.keyEditors.set(key, owners);
	}

	/**
	 * The criteria needed for a player to pass for the specified keys to be editable
	 * @param keys Keys to edit
	 * @param owners The owners for this key
	 */
	public setEditorCriteriaForKeys(keys: Array<Keyable>, owners: OwnerCriterias) {
		if (this.isPendingGC()) return;
		keys.forEach((key) => this.setEditorCriteriaForKey(key, owners));
	}

	/**
	 * Attempt to edit a key based on the given player. This should already be handled by a remote function.
	 * @param player The player
	 * @param key The key to edit
	 * @param value The new value
	 * @returns Whether it was successful
	 */
	public tryToEditKey(player: Player, key: Keyable, value: Valuable): boolean {
		const criterias = this.keyEditors.get(key);
		if (criterias !== undefined && ServerDataObject.IsAOwner(player, criterias)) {
			this.setValue(key, value);
			return true;
		}
		return false;
	}
}

Players.PlayerAdded.Connect((player) => {
	player.AddTag("default");
	ServerDataObject.syncAllForNewPlayer(player);
});

function GenerateIDForInstance(instance: Instance) {
	if (instance.GetAttribute("uuid") === undefined) {
		const uuid = HttpService.GenerateGUID();
		instance.SetAttribute("uuid", uuid);
		instance.AddTag(uuid);
	}
}

Workspace.DescendantAdded.Connect((instance) => GenerateIDForInstance(instance));

Workspace.GetDescendants().forEach((instance) => GenerateIDForInstance(instance));

AddTickable("[Flush Data Objects]", (tickable) => ServerDataObject.flushAll());

EditFunction.OnServerInvoke = function (player: Player, holder: unknown, key: unknown, value: unknown) {
	const holderCast = holder as Holdable;
	const dataObject = ActiveDataObjects.get(holderCast);
	if (dataObject !== undefined && dataObject instanceof ServerDataObject) {
		return dataObject.tryToEditKey(player, key as Keyable, value as Valuable);
	}
	return false;
};

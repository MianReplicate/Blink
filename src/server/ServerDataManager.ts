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

type PlayerAccessorPredicate = (player: Player) => boolean;
type PlayerKeyPredicate = (player: Player) => PlayerKeyAccessibility;
type PlayerKeyAccessibility = { canSeeKey: boolean; canSeeValue: boolean; canEditValue: boolean };

const PendingGCFlush = new Array<DataObject<Holdable>>();

export class ServerDataObject<T extends Holdable> extends DataObject<T> {
	private accessor: PlayerAccessorPredicate;
	private keyAccessibilities: Map<Keyable, PlayerKeyPredicate>;
	private dirtyKeys: Set<Keyable>;
	private uuid: string | undefined;

	protected constructor(holder: T) {
		super(holder);
		this.keyAccessibilities = new Map();
		this.dirtyKeys = new Set();
		this.accessor = () => false;

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
		if (this.keyAccessibilities.has(key)) this.dirtyKeys.add(key);
	}

	public override destroy(): void {
		super.destroy();
		this.uuid = undefined;
		PendingGCFlush.push(this);
	}

	private static GetPlayerKeyAccessibility(player: Player, callback: PlayerKeyPredicate): PlayerKeyAccessibility {
		return callback !== undefined
			? callback(player)
			: { canSeeKey: false, canSeeValue: false, canEditValue: false };
	}

	private static GetPlayerKeyAccessibilities(
		players: Array<Player>,
		callback: PlayerKeyPredicate,
	): Map<Player, PlayerKeyAccessibility> {
		const map = new Map<Player, PlayerKeyAccessibility>();

		players.forEach((player) => map.set(player, ServerDataObject.GetPlayerKeyAccessibility(player, callback)));

		return map;
	}

	private static GetPlayerAccessibility(player: Player, callback: PlayerAccessorPredicate) {
		return callback !== undefined ? callback(player) : false;
	}

	private static GetPlayerAccessibilities(players: Array<Player>, callback: PlayerAccessorPredicate) {
		return players.filter((player) => callback(player));
	}

	/**
	 * Flushes all dirty keys and replicates them to all valid players.
	 */
	private flush(): Map<Player, Map<Keyable, Valuable>> | undefined {
		if (this.isPendingGC() || this.dirtyKeys.isEmpty()) return undefined;

		const playerStorageMap = new Map<Player, Map<Keyable, Valuable>>();
		const players = Players.GetPlayers();

		this.dirtyKeys.forEach((key) => {
			const criterias = this.keyAccessibilities.get(key) as PlayerKeyPredicate;
			const accessorPlayers = ServerDataObject.GetPlayerAccessibilities(players, this.accessor);
			const matchingPlayers = Object.entries(
				ServerDataObject.GetPlayerKeyAccessibilities(players, criterias),
			).filter((entry) => accessorPlayers.includes(entry[0]));

			let value = this.getValue(key);
			if (typeIs(value, "Instance")) value = value.GetAttribute("uuid") as string;

			matchingPlayers.forEach((entry) => {
				const player = entry[0];
				const accessibility = entry[1];

				if (accessibility.canSeeKey) {
					let storage = playerStorageMap.get(player);
					if (!storage) {
						storage = new Map();
						playerStorageMap.set(player, storage);
					}
					storage.set(key, accessibility.canSeeValue ? value : "unreplicated");
				}
			});
		});

		// const uuid = this.uuid;
		// const holderProxy: HoldableProxy = { holder, uuid };
		// playerStorageMap.forEach((storage, player) => ReplicateToPlayer(player, { holderProxy, storage }));

		this.dirtyKeys.clear();

		return playerStorageMap;
	}

	/**
	 * Flushes all active data objects and syncs them to all players. This should be run once in the main central loop.
	 */
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

				if (this.GetPlayerAccessibility(player, dataObject.accessor)) {
					dataObject.keyAccessibilities.forEach((predicate, key) => {
						const accessibility = this.GetPlayerKeyAccessibility(player, predicate);
						if (accessibility.canSeeKey) {
							storage.set(key, accessibility.canSeeValue ? dataObject.getValue(key) : "unreplicated");
						}
					});

					const uuid = dataObject.uuid;
					const holderProxy: HoldableProxy = { holder, uuid };
					const replicatedDataObject: ReplicatedDataObject = { holderProxy, pendingGC: false, storage };
					objects.push(replicatedDataObject);
				}
			}
		});

		ReplicateToPlayer(player, objects);

		Debug("Syncing", objects, "to", player);
	}

	/**
	 * Sets an accessor predicate for the data object
	 * @param predicate Tests for whether the player can see the data object
	 */
	public setCriteriaForDataObject(predicate: PlayerAccessorPredicate) {
		if (this.isPendingGC()) return;

		this.accessor = predicate;
	}

	/**
	 * Set a key predicate for the specified key
	 * @param keys Keys to replicate
	 * @param predicate Tests for whether a player can see a key, see its value, and edit the value
	 */
	public setPlayerCriteriaForKey(key: Keyable, predicate: PlayerKeyPredicate) {
		if (this.isPendingGC()) return;
		this.keyAccessibilities.set(key, predicate);
		this.dirtyKeys.add(key);
	}

	/**
	 * Set a key predicate for the specified keys
	 * @param keys Keys to replicate
	 * @param predicate Tests for whether a player can see a key, see its value, and edit the value
	 */
	public setPlayerCriteriaForKeys(keys: Array<Keyable>, predicate: PlayerKeyPredicate) {
		if (this.isPendingGC()) return;
		keys.forEach((key) => this.setPlayerCriteriaForKey(key, predicate));
	}

	/**
	 * Attempt to edit a key based on the given player. This should already be handled by a remote function.
	 * @param player The player
	 * @param key The key to edit
	 * @param value The new value
	 * @returns Whether it was successful
	 */
	public tryToEditKey(player: Player, key: Keyable, value: Valuable): boolean {
		const predicate = this.keyAccessibilities.get(key);
		if (predicate !== undefined && ServerDataObject.GetPlayerKeyAccessibility(player, predicate).canEditValue) {
			this.setValue(key, value);
			return true;
		}
		return false;
	}
}

Players.PlayerAdded.Connect((player) => ServerDataObject.syncAllForNewPlayer(player));

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

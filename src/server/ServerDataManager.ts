import { Object } from "@rbxts/luau-polyfill";
import { HttpService, Players, Workspace } from "@rbxts/services";
import { DataManager, Debug, Holdable, Keyable, NetworkedDataObject, Valuable } from "shared/DataManager";
import {
	EditFunction,
	HoldableProxy,
	ReplicatedDataObject,
	ReplicatedDataObjects,
	ReplicateToPlayer,
} from "shared/ReplicateManager";
import { TickManager } from "shared/TickManager";

type PlayerAccessorPredicate = (player: Player) => boolean;
type PlayerKeyPredicate = (player: Player) => PlayerKeyAccessibility;
type PlayerKeyAccessibility = { canSeeKey: boolean; canSeeValue: boolean; canEditValue: boolean };

const PendingGCFlush = new Array<NetworkedDataObject<Holdable>>();

export class ServerDataObject<T extends Holdable> extends NetworkedDataObject<T> {
	private accessor: PlayerAccessorPredicate;
	private keyAccessibilities: Map<Keyable, PlayerKeyPredicate>;
	private dirtyKeys: Set<Keyable>;

	protected constructor(holder: T, tags: Array<string>) {
		super(holder, tags);
		this.keyAccessibilities = new Map();
		this.dirtyKeys = new Set();
		this.accessor = () => false;
	}

	public static getOrConstruct<T extends Holdable>(
		holder: T,
		tags: Array<string>,
		createCallback = () => new ServerDataObject<T>(holder, tags),
	): ServerDataObject<T> {
		return super.getOrConstruct(holder, tags, createCallback) as ServerDataObject<T>;
	}

	public static waitFor<T extends Holdable>(
		holder: T,
		tags: Array<string>,
		secondsToWait: number = math.huge,
	): ServerDataObject<T> | undefined {
		const dataObject = super.waitFor(holder, tags, secondsToWait);
		if (dataObject === undefined) return undefined;
		return dataObject as ServerDataObject<T>;
	}

	public getInProxyForm(): HoldableProxy {
		const holder = this.getHolder();
		const tags = this.tags;
		const uuid = this.uuid;

		return { holder, tags, uuid };
	}

	public override setValue(key: Keyable, value: Valuable): void {
		if (this.isPendingGC()) return;
		super.setValue(key, value);
		if (this.keyAccessibilities.has(key)) this.dirtyKeys.add(key);
	}

	public override destroy(): void {
		super.destroy();
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

			let value = this.getValue<Valuable>(key);
			if (typeIs(value, "Instance")) value = value.GetAttribute("uuid") as string;

			const toUse = typeIs(key, "Instance") ? (key.GetAttribute("uuid") as string) : key;

			matchingPlayers.forEach((entry) => {
				const player = entry[0];
				const accessibility = entry[1];

				if (accessibility.canSeeKey) {
					let storage = playerStorageMap.get(player);
					if (!storage) {
						storage = new Map();
						playerStorageMap.set(player, storage);
					}

					storage.set(toUse, accessibility.canSeeValue ? value : "unreplicated");
				}
			});
		});

		this.dirtyKeys.clear();

		return playerStorageMap;
	}

	/**
	 * Flushes all active data objects and syncs them to all players. This should be run once in the main central loop.
	 */
	public static flushAll() {
		const playerToDataObjects = new Map<Player, ReplicatedDataObjects>();

		DataManager.getObjects().forEach((dataObject) => {
			if (dataObject instanceof ServerDataObject) {
				const playerStorageMap = dataObject.flush();
				playerStorageMap?.forEach((storage, player) => {
					let dataObjects = playerToDataObjects.get(player);
					if (dataObjects === undefined) {
						dataObjects = new Array();
						playerToDataObjects.set(player, dataObjects);
					}

					const holderProxy = dataObject.getInProxyForm();
					dataObjects.push({ holderProxy, pendingGC: false, dirtyKeys: storage });
				});
			}
		});

		PendingGCFlush.forEach((dataObject) => {
			if (dataObject instanceof ServerDataObject) {
				const holderProxy = dataObject.getInProxyForm();
				const object: ReplicatedDataObject = { holderProxy, pendingGC: true, dirtyKeys: undefined };

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

		DataManager.getObjects().forEach((dataObject, holder) => {
			if (dataObject instanceof ServerDataObject) {
				const storage: Map<Keyable, Valuable> = new Map();

				if (this.GetPlayerAccessibility(player, dataObject.accessor)) {
					dataObject.keyAccessibilities.forEach((predicate, key) => {
						const accessibility = this.GetPlayerKeyAccessibility(player, predicate);
						if (accessibility.canSeeKey) {
							storage.set(key, accessibility.canSeeValue ? dataObject.getValue(key) : "unreplicated");
						}
					});

					const holderProxy = dataObject.getInProxyForm();
					const replicatedDataObject: ReplicatedDataObject = {
						holderProxy,
						pendingGC: false,
						dirtyKeys: storage,
					};
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
		Debug(player, "tried to edit", key, "but was denied permission!");
		return false;
	}
}

Players.PlayerAdded.Connect((player) => ServerDataObject.syncAllForNewPlayer(player));

TickManager.addTickable("[Flush Data Objects]", (tickable) => ServerDataObject.flushAll());

EditFunction.OnServerInvoke = function (player: Player, holderProxy: unknown, key: unknown, value: unknown) {
	const holderCast = holderProxy as HoldableProxy;
	const dataObject = DataManager.get(holderCast.holder, holderCast.tags);
	if (dataObject !== undefined && dataObject instanceof ServerDataObject) {
		return dataObject.tryToEditKey(player, key as Keyable, value as Valuable);
	}
	return false;
};

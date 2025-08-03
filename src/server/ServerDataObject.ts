import { Object } from "@rbxts/luau-polyfill";
import { HttpService, Players, Workspace } from "@rbxts/services";
import {
	DataManager,
	Debug,
	Holdable,
	Keyable,
	NetworkedDataObject,
	Replicatable,
	Valuable,
} from "shared/Managers/DataManager";
import {
	EditFunction,
	HoldableProxy,
	ReplicatedDataObject,
	ReplicatedDataObjects,
	ReplicateToPlayer,
	ReplicateType,
} from "shared/Managers/ReplicateManager";
import { TickManager } from "shared/Managers/TickManager";

export type PlayerAccessorPredicate = (player: Player) => boolean;
export type PlayerKeyPredicate = (player: Player) => PlayerKeyAccessibility;
type PlayerKeyAccessibility = { canSeeKey: boolean; canSeeValue: boolean; canEditValue: boolean };

const PendingGCFlush = new Array<NetworkedDataObject<Holdable>>();

export class ServerDataObject<T extends Holdable> extends NetworkedDataObject<T> {
	private accessor: PlayerAccessorPredicate;
	private keyReplicateTypes: Map<Keyable, ReplicateType>;
	private keyAccessibilities: Map<Keyable, PlayerKeyPredicate>;
	private dirtyKeys: Set<Keyable>;
	private dirtyRemovedKeys: Set<Keyable>;

	protected constructor(holder: T, tags: Array<string>) {
		super(holder, tags);
		this.keyAccessibilities = new Map();
		this.keyReplicateTypes = new Map();
		this.dirtyKeys = new Set();
		this.dirtyRemovedKeys = new Set();
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

	public removeKey(key: Keyable) {
		if (this.isPendingGC()) return;
		super.removeKey(key);
		if (this.keyAccessibilities.has(key)) {
			this.dirtyRemovedKeys.add(key);
		} else {
			this.keyAccessibilities.delete(key);
			this.keyReplicateTypes.delete(key);
		}
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
	private flush() {
		if (this.isPendingGC() || (this.dirtyKeys.isEmpty() && this.dirtyRemovedKeys.isEmpty())) return undefined;

		const reliablePlayerStorageMap = new Map<Player, Map<Keyable, Valuable>>();
		const unreliablePlayerStorageMap = new Map<Player, Map<Keyable, Valuable>>();

		const players = Players.GetPlayers();
		const keys = new Set([...this.dirtyKeys, ...this.dirtyRemovedKeys]);

		keys.forEach((key) => {
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
					const replicateType = this.keyReplicateTypes.get(key) || ReplicateType.Reliable;
					const storageMap =
						replicateType === ReplicateType.Reliable
							? reliablePlayerStorageMap
							: unreliablePlayerStorageMap;

					let storage = storageMap.get(player);
					if (!storage) {
						storage = new Map();
						storageMap.set(player, storage);
					}

					const replicatable =
						value === undefined ||
						(value !== undefined &&
							(!typeIs(value, "table") ||
								(typeIs(value, "table") && (value as Replicatable).replicatable)));
					if (value === undefined || !this.storage.has(key)) value = "undefined"; // so the client can see it's undefined
					storage.set(
						toUse,
						(accessibility.canSeeValue && replicatable) || !this.storage.has(key) ? value : "unreplicated",
					);
				}
			});

			if (this.dirtyRemovedKeys.has(key)) {
				this.keyAccessibilities.delete(key);
				this.keyReplicateTypes.delete(key);
			}
		});

		this.dirtyKeys.clear();

		return { reliable: reliablePlayerStorageMap, unreliable: unreliablePlayerStorageMap };
	}

	/**
	 * Flushes all active data objects and syncs them to all players. This should be run once in the main central loop.
	 */
	public static flushAll() {
		const reliablePlayerToDataObjects = new Map<Player, ReplicatedDataObjects>();
		const unreliablePlayerToDataObjects = new Map<Player, ReplicatedDataObjects>();

		DataManager.getObjects().forEach((dataObject) => {
			if (dataObject instanceof ServerDataObject) {
				const playerMaps = dataObject.flush();
				if (playerMaps !== undefined) {
					playerMaps.reliable.forEach((storage, player) => {
						let dataObjects = reliablePlayerToDataObjects.get(player);
						if (dataObjects === undefined) {
							dataObjects = new Array();
							reliablePlayerToDataObjects.set(player, dataObjects);
						}

						const holderProxy = dataObject.getInProxyForm();
						dataObjects.push({ holderProxy, pendingGC: false, dirtyKeys: storage });
					});

					playerMaps.unreliable.forEach((storage, player) => {
						let dataObjects = unreliablePlayerToDataObjects.get(player);
						if (dataObjects === undefined) {
							dataObjects = new Array();
							unreliablePlayerToDataObjects.set(player, dataObjects);
						}

						const holderProxy = dataObject.getInProxyForm();
						dataObjects.push({ holderProxy, pendingGC: false, dirtyKeys: storage });
					});
				}
			}
		});

		PendingGCFlush.forEach((dataObject) => {
			if (dataObject instanceof ServerDataObject) {
				const holderProxy = dataObject.getInProxyForm();
				const object: ReplicatedDataObject = { holderProxy, pendingGC: true, dirtyKeys: undefined };

				Players.GetPlayers().forEach((player) => {
					let dataObjects = reliablePlayerToDataObjects.get(player);
					if (dataObjects === undefined) {
						dataObjects = new Array();
						reliablePlayerToDataObjects.set(player, dataObjects);
					}
					dataObjects.push(object);
				});
			}
		});
		PendingGCFlush.clear();

		if (reliablePlayerToDataObjects.size() > 0) {
			Debug("Flushing Reliable", reliablePlayerToDataObjects);

			reliablePlayerToDataObjects.forEach((objects, player) =>
				ReplicateToPlayer(player, objects, ReplicateType.Reliable),
			);
		}

		if (unreliablePlayerToDataObjects.size() > 0) {
			Debug("Flushing Unreliable", unreliablePlayerToDataObjects);

			unreliablePlayerToDataObjects.forEach((objects, player) =>
				ReplicateToPlayer(player, objects, ReplicateType.Unreliable),
			);
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
							let value = dataObject.getValue<Valuable>(key);
							const replicatable =
								value === undefined ||
								(value !== undefined &&
									(!typeIs(value, "table") ||
										(typeIs(value, "table") && (value as Replicatable).replicatable)));
							if (value === undefined) value = "undefined"; // so the client can see it's undefined
							storage.set(key, accessibility.canSeeValue && replicatable ? value : "unreplicated");
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

		ReplicateToPlayer(player, objects, ReplicateType.Reliable);

		Debug("Syncing", objects, "to", player);
	}

	public setKeyReliability(key: Keyable, replicateType: ReplicateType) {
		this.keyReplicateTypes.set(key, replicateType);
	}

	/**
	 * Sets an accessor predicate for the data object
	 * @param predicate Tests for whether the player can see the data object
	 */
	public setCriteriaForDataObject(predicate: PlayerAccessorPredicate) {
		if (this.isPendingGC()) return;

		this.accessor = predicate;
	}

	public setFutureCriteriaForKeys(predicate: PlayerKeyPredicate) {
		return this.addListener({
			callback: (key) => {
				this.setPlayerCriteriaForKey(key, predicate);
			},
		});
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

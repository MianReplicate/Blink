import { HttpService, Players, Workspace } from "@rbxts/services";
import {
	ActiveDataObjects,
	AddTickable,
	DataObject,
	Debug,
	Holdable,
	HoldableProxy,
	Keyable,
	ReplicatedDataObject,
	ReplicateToPlayer,
	Valuable,
} from "shared/DataManager";

type Replicatables = Array<Player | string>;

const UUIDToInstances = new Map<string, Instance>();

export class ServerDataObject<T extends Holdable> extends DataObject<T> {
	private keyReplicators: Map<Keyable, Replicatables>;
	private dirtyKeys: Set<Keyable>;
	private uuid: string | undefined;

	protected constructor(holder: T) {
		super(holder);
		this.keyReplicators = new Map();
		this.dirtyKeys = new Set();

		if (typeIs(holder, "Instance")) {
			this.uuid = HttpService.GenerateGUID();
			UUIDToInstances.set(this.uuid, holder);
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
		if (this.uuid !== undefined) UUIDToInstances.delete(this.uuid);
		this.uuid = undefined;
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

	public flush() {
		if (this.isPendingGC() || this.dirtyKeys.isEmpty()) return;
		const holder = this.getHolder();
		if (typeIs(holder, "Instance")) {
			if (!holder.IsDescendantOf(Workspace)) return; // no point if it's not a descendant of workspace
		}

		const playerStorageMap = new Map<Player, Map<Keyable, Valuable>>();
		const players = Players.GetPlayers();

		this.dirtyKeys.forEach((key) => {
			const keyReplicators = this.keyReplicators.get(key);
			const matchingPlayers = players.filter(
				(player) =>
					!keyReplicators
						?.filter(
							(replicator) =>
								replicator === player || (typeIs(replicator, "string") && player.HasTag(replicator)),
						)
						.isEmpty(),
			);

			const value = this.getValue(key);
			matchingPlayers.forEach((player) => {
				let storage = playerStorageMap.get(player);
				if (!storage) {
					storage = new Map();
					playerStorageMap.set(player, storage);
				}
				storage.set(key, value);
			});
		});

		const uuid = this.uuid;
		const holderProxy: HoldableProxy = { holder, uuid };
		playerStorageMap.forEach((storage, player) => ReplicateToPlayer(player, { holderProxy, storage }));

		Debug("Flushing", holder, playerStorageMap);
		this.dirtyKeys.clear();
	}

	public syncToPlayerIfAllowed(player: Player): ReplicatedDataObject | undefined {
		if (this.isPendingGC()) return;

		const holder = this.getHolder();
		const storage: Map<Keyable, Valuable> = new Map();

		this.keyReplicators.forEach((replicatables, key) => {
			if (
				!replicatables
					.filter((value) => value === player || (typeIs(value, "string") && player.HasTag(value)))
					.isEmpty()
			) {
				storage.set(key, this.getValue(key));
			}
		});

		const uuid = typeIs(holder, "Instance") ? (holder.GetAttribute("uuid") as string) : undefined;
		const holderProxy: HoldableProxy = { holder, uuid };
		const replicatedDataObject: ReplicatedDataObject = { holderProxy, storage };
		ReplicateToPlayer(player, replicatedDataObject);
		return replicatedDataObject;
	}

	public replicateKeyTo(key: Keyable, replicatables: Replicatables) {
		if (this.isPendingGC()) return;
		this.keyReplicators?.set(key, replicatables);
		this.dirtyKeys.add(key);
		// this.replicateToAll(key);
	}

	public replicateKeysTo(keys: Array<Keyable>, replicatables: Replicatables) {
		if (this.isPendingGC()) return;
		keys.forEach((key) => this.replicateKeyTo(key, replicatables));
	}
}

Players.PlayerAdded.Connect((player) => {
	player.AddTag("default");
	ActiveDataObjects.forEach((dataObject) => {
		if (dataObject instanceof ServerDataObject) {
			const dataReplicated = dataObject.syncToPlayerIfAllowed(player);
			Debug("Syncing", dataObject.getHolder(), "to", player, dataReplicated);
		}
	});
});

Workspace.DescendantAdded.Connect((instance) => {
	if (instance.GetAttribute("uuid") === undefined) instance.SetAttribute("uuid", HttpService.GenerateGUID());
});

Workspace.GetDescendants().forEach((instance) => {
	if (instance.GetAttribute("uuid") === undefined) instance.SetAttribute("uuid", HttpService.GenerateGUID());
});

AddTickable((tickable) => {
	ActiveDataObjects.forEach((dataObject) => {
		if (dataObject instanceof ServerDataObject) {
			dataObject.flush();
		}
	});
});

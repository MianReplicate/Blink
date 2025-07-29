import { ReplicatedStorage, RunService, Workspace } from "@rbxts/services";

type Listener = (key: Keyable, value: Valuable, oldValue: Valuable | undefined) => void;

export type HoldableProxy = { holder: Holdable; uuid: string | undefined };
export type Holdable = Instance | string;
export type Valuable = Instance | string | number | undefined;
export type Keyable = Instance | string;
export type Tickable = (deltaTime: number) => void;

export const toDebug = false;

// export type ReplicatedKey = {
// 	holder: Holdable;
// 	key: Keyable;
// 	value: Valuable;
// };

export type ReplicatedDataObject = {
	holderProxy: HoldableProxy;
	storage: Map<Keyable, Valuable>;
};

export const ReplicateEvent =
	(ReplicatedStorage.FindFirstChild("ReplicateEvent") as RemoteEvent) || new Instance("RemoteEvent");
ReplicateEvent.Name = "ReplicateEvent";
ReplicateEvent.Parent = ReplicatedStorage;

const ToTick = new Array<Tickable>();

export const ActiveDataObjects: Map<Holdable, DataObject<Holdable>> = new Map();

export function Debug(...args: Array<unknown>) {
	if (toDebug) print(...args);
}

export function ReplicateToPlayer(player: Player, toReplicate: ReplicatedDataObject) {
	ReplicateEvent.FireClient(player, toReplicate);
}

export function AddTickable(tickable: Tickable) {
	ToTick.push(tickable);
}

/**
 * A way to assign values with keys to unknown object alongside adding replication, and listener capabilities for these values.
 */
export class DataObject<T extends Holdable> {
	private holder: T;
	private storage: Map<Keyable, Valuable>;
	private listeners: Map<string, Listener>;
	private pendingGC: boolean;

	/**
	 *
	 * @param holder The holder of this data
	 */
	protected constructor(holder: T) {
		this.holder = holder;
		this.storage = new Map();
		this.listeners = new Map();
		this.pendingGC = false;
		ActiveDataObjects.set(this.holder, this);
	}

	public static construct<T extends Holdable>(holder: T): DataObject<T> {
		if (ActiveDataObjects.has(holder)) {
			return ActiveDataObjects.get(holder) as DataObject<T>;
		}
		return new DataObject<T>(holder);
	}

	public static waitFor<T extends Holdable>(holder: T, secondsToWait: number): DataObject<T> | undefined {
		let dataObject: DataObject<T> | undefined = undefined;
		const heartbeat = RunService.Heartbeat.Connect((deltaTime) => {
			secondsToWait -= deltaTime;

			dataObject = ActiveDataObjects.get(holder) as DataObject<T>;

			if (secondsToWait <= 0 || dataObject !== undefined) heartbeat.Disconnect();
		});

		while (heartbeat.Connected && dataObject === undefined) {
			task.wait();
		}
		return dataObject;
	}

	public destroy() {
		this.pendingGC = true;
		ActiveDataObjects.delete(this.holder);
		this.listeners.clear();
		this.storage.clear();
	}

	public isPendingGC() {
		return this.pendingGC;
	}

	/**
	 *
	 * @param key The key to set for this value
	 * @param value The value to store
	 */
	public setValue(key: Keyable, value: Valuable) {
		if (this.pendingGC) return;
		const oldValue = this.storage.get(key);
		this.storage.set(key, value);

		this.listeners.forEach((listener) => listener(key, value, oldValue));
	}

	/**
	 *
	 * @param key The key used to store the value
	 * @returns The value assigned to the key
	 */
	public getValue(key: Keyable): Valuable {
		return this.storage.get(key);
	}

	/**
	 *
	 * @param name The name to assign to the listener
	 * @param listener A function that is called whenever values are set
	 */
	public addListener(name: string, listener: Listener) {
		if (this.pendingGC) return;
		this.listeners.set(name, listener);
	}

	/**
	 *
	 * @param name The name of the listener to remove
	 */
	public removeListener(name: string) {
		this.listeners.delete(name);
	}

	/**
	 *
	 * @returns The holder assigned to this data object
	 */
	public getHolder(): T {
		return this.holder;
	}
}

RunService.Heartbeat.Connect((deltaTime) => {
	// end is highest priority (runs first), beginning is lowest priority (runs last)
	for (let i = ToTick.size() - 1; i >= 0; i--) {
		ToTick[i](deltaTime);
	}
});

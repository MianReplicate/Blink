// test netwokring capabilities
// maybe implement serializing and deserializing for data saving

import Object from "@rbxts/object-utils";
import { HttpService, ReplicatedStorage, RunService, Workspace } from "@rbxts/services";
import { HoldableProxy } from "./ReplicateManager";

type Listener = {
	key?: Keyable | undefined;
	callback: (key: Keyable, value: Valuable, oldValue: Valuable | undefined) => void;
};

export type Holdable = Instance | string;
export type Keyable = Holdable | number;
export type Valuable = Instance | string | number | boolean | Valuable[] | Map<Keyable, Valuable> | undefined;
export type Tickable = (deltaTime: number) => void;

export const toDebug = true;

// export type ReplicatedKey = {
// 	holder: Holdable;
// 	key: Keyable;
// 	value: Valuable;
// };

export function Debug(...args: Array<unknown>) {
	if (toDebug) print(...args);
}

export namespace DataManager {
	const ToTick = new Map<string, Tickable>();
	export let ToTickEntries = new Array<[string, Tickable]>();

	const DataObjects: Array<DataObject<Holdable>> = new Array();

	export function findDataObject(holder: Holdable, tags: Array<string>): number {
		return DataObjects.findIndex((dataObject) => {
			const compareTags = dataObject.getTags();
			return dataObject.getHolder() === holder && tags.every((tag) => compareTags.includes(tag));
		});
	}

	export function removeDataObject(dataObject: DataObject<Holdable>) {
		const index = findDataObject(dataObject.getHolder(), dataObject.getTags());
		DataObjects.remove(index);
	}

	export function addDataObject(dataObject: DataObject<Holdable>) {
		DataObjects.push(dataObject);
	}

	export function getDataObject(holder: Holdable, tags: Array<string>): DataObject<Holdable> | undefined {
		const index = findDataObject(holder, tags);
		if (index !== -1) return DataObjects[index];
		return undefined;
	}

	export function getDataObjects() {
		return DataObjects;
	}

	export function AddTickable(name: string, tickable: Tickable) {
		ToTick.set(name, tickable);
		ToTickEntries = Object.entries(ToTick);

		print("Added " + name + " for ticking");
	}
}

/**
 * A way to assign values with keys to unknown object alongside adding replication, and listener capabilities for these values.
 */
export class DataObject<T extends Holdable> {
	private holder: T;
	private storage: Map<Keyable, Valuable>;
	private listeners: Map<string, Listener>;
	private pendingGC: boolean;
	private tags: Array<string>;

	/**
	 * Constructs a new data object
	 * @param holder The holder of this data
	 */
	protected constructor(holder: T, tags: Array<string>) {
		this.holder = holder;
		this.storage = new Map();
		this.listeners = new Map();
		this.pendingGC = false;
		this.tags = tags;

		DataManager.addDataObject(this);
	}

	/**
	 * Gets or constructs a new data object for a holder
	 * @param holder The object to create data for
	 * @param parentDataObject? The parent that should be responsible for this data object if there is one
	 * @returns A data object of the holder
	 */
	public static getOrConstruct<T extends Holdable>(
		holder: T,
		tags: Array<string>,
		createCallback = () => new DataObject<T>(holder, tags),
	): DataObject<T> {
		const object = DataManager.getDataObject(holder, tags);
		return object !== undefined ? (object as DataObject<T>) : createCallback();
	}

	/**
	 * Waits for a data object to be created and then returns it
	 * @param holder The object that data is being held under
	 * @param secondsToWait How long to wait for this holder to exist
	 * @returns The existing holder
	 */
	public static waitFor<T extends Holdable>(
		holder: T,
		tags: Array<string>,
		secondsToWait: number = math.huge,
	): DataObject<T> | undefined {
		let dataObject: DataObject<T> | undefined = undefined;
		const heartbeat = RunService.Heartbeat.Connect((deltaTime) => {
			secondsToWait -= deltaTime;

			dataObject = DataManager.getDataObject(holder, tags) as DataObject<T>;

			if (secondsToWait <= 0 || dataObject !== undefined) heartbeat.Disconnect();
		});

		while (heartbeat.Connected && dataObject === undefined) {
			task.wait();
		}
		return dataObject;
	}

	/**
	 * Destroys the data object
	 */
	public destroy() {
		this.pendingGC = true;

		DataManager.removeDataObject(this);
		this.listeners.clear();
		this.storage.clear();
	}

	/**
	 * Use for determining if the data object should no longer be active
	 * @returns Get whether the data object is pending garbage collection
	 */
	public isPendingGC() {
		return this.pendingGC;
	}

	/**
	 * Set a key to a value
	 * @param key The key to set for this value
	 * @param value The value to store
	 */
	public setValue(key: Keyable, value: Valuable) {
		if (this.pendingGC) return;
		const oldValue = this.storage.get(key);

		this.storage.set(key, value);

		this.listeners.forEach((listener) => {
			if (listener.key === undefined || listener.key === key) {
				listener.callback(key, value, oldValue);
			}
		});
	}

	public removeKey(key: Keyable) {
		if (this.pendingGC) return;
		const oldValue = this.storage.get(key);
		this.storage.delete(key);

		this.listeners.forEach((listener) => {
			if (listener.key === undefined || listener.key === key) {
				listener.callback(key, "deleted", oldValue);
			}
		});
	}

	public addValue(value: Valuable) {
		if (this.pendingGC) return;
		this.setValue(this.storage.size(), value);
	}

	public findValue(value: Valuable): Keyable | undefined {
		if (this.pendingGC) return;
		const filteredValues = Object.entries(this.storage).filter((entry) => entry[1] === value);
		if (!filteredValues.isEmpty()) return filteredValues[0][0] as Keyable;

		return undefined;
	}

	/**
	 * Get the value assigned to the key
	 * @param key The key used to store the value
	 * @returns The value assigned to the key
	 */
	public getValue<Valuable>(key: Keyable): Valuable {
		return this.storage.get(key) as Valuable;
	}

	/**
	 * Add a new listener that is called when the specified key is altered or when a value is set if there is no set key
	 * @param listener A function that is called whenever values are set
	 * @returns A callback to stop the listener
	 */
	public addListener(listener: Listener) {
		if (this.pendingGC) return;

		const uuid = HttpService.GenerateGUID();
		this.listeners.set(uuid, listener);

		return () => this.listeners.delete(uuid);
	}

	public getTags() {
		return this.tags;
	}

	/**
	 * Gets the holder for this data object
	 * @returns The holder assigned to this data object
	 */
	public getHolder(): T {
		return this.holder;
	}

	/**
	 * Get the complete storage for this data object. USE only for viewing the keys and values. DO not alter anything, you could seriously fuck something up.
	 * @returns The storage of the object
	 */
	public getStorage() {
		return this.storage;
	}
}

RunService.Heartbeat.Connect((deltaTime) => {
	// end is highest priority (runs first), beginning is lowest priority (runs last)
	for (let i = DataManager.ToTickEntries.size() - 1; i >= 0; i--) {
		DataManager.ToTickEntries[i][1](deltaTime);
	}
});

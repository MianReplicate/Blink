// test netwokring capabilities
// maybe implement serializing and deserializing for data saving

import { HttpService, ReplicatedStorage, RunService, Workspace } from "@rbxts/services";
import { HoldableProxy } from "./ReplicateManager";
import { Object } from "@rbxts/luau-polyfill";

type Listener<T extends Valuable> = {
	key?: Keyable | undefined;
	callback: (key: Keyable, value: T, oldValue: T | undefined) => void;
};

export type Holdable = Instance | string;
export type Keyable = Holdable | number;
export type Valuable =
	| Instance
	| string
	| number
	| boolean
	| Valuable[]
	| Map<Keyable, Valuable>
	| Replicatable
	| undefined
	| unknown;

export interface Replicatable {
	replicatable: boolean;
}

export const toDebug = false;

// export type ReplicatedKey = {
// 	holder: Holdable;
// 	key: Keyable;
// 	value: Valuable;
// };

export function Debug(...args: Array<unknown>) {
	if (toDebug) print(...args);
}

export namespace DataManager {
	const DataObjects: Array<DataObject<Holdable>> = new Array();

	export function find(holder: Holdable, tags: ReadonlyArray<string>): number {
		return DataObjects.findIndex((dataObject) => {
			const compareTags = dataObject.getTags();
			return dataObject.getHolder() === holder && tags.every((tag) => compareTags.includes(tag));
		});
	}

	export function remove(dataObject: DataObject<Holdable>) {
		const index = find(dataObject.getHolder(), dataObject.getTags());
		DataObjects.remove(index);
	}

	export function add(dataObject: DataObject<Holdable>) {
		DataObjects.push(dataObject);
	}

	export function get(holder: Holdable, tags: ReadonlyArray<string>): DataObject<Holdable> | undefined {
		const index = find(holder, tags);
		if (index !== -1) return DataObjects[index];
		return undefined;
	}

	export function getTagged(tags: ReadonlyArray<string>): Array<DataObject<Holdable>> {
		return DataObjects.filter((dataObject) => {
			const compareTags = dataObject.getTags();
			return tags.every((tag) => compareTags.includes(tag));
		});
	}

	export function getObjects() {
		return DataObjects as Array<NetworkedDataObject<Holdable>>;
	}
}

/**
 * A way to assign values with keys to unknown object alongside adding replication, and listener capabilities for these values.
 */
class DataObject<T extends Holdable> {
	private holder: T;
	protected storage: Map<Keyable, Valuable>;
	private listeners: Map<string, Listener<unknown>>;
	private pendingGC: boolean;
	protected tags: ReadonlyArray<string>;

	/**
	 * Constructs a new data object
	 * @param holder The holder of this data
	 */
	protected constructor(holder: T, tags: Array<string>) {
		if (tags.isEmpty()) error("Need at least one tag to create a DataObject!");

		this.holder = holder;
		this.storage = new Map();
		this.listeners = new Map();
		this.pendingGC = false;
		this.tags = Object.freeze(tags);

		DataManager.add(this);
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
		const object = DataManager.get(holder, tags);
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

			dataObject = DataManager.get(holder, tags) as DataObject<T>;

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

		DataManager.remove(this);
		this.listeners.clear();
		this.storage.clear();
		Object.freeze(this.listeners);
		Object.freeze(this.storage);
	}

	/**
	 * Use for determining if the data object should no longer be active
	 * @returns Get whether the data object is pending garbage collection
	 */
	public isPendingGC() {
		return this.pendingGC;
	}

	protected callListeners(key: Keyable, value: Valuable, oldValue: Valuable) {
		this.listeners.forEach((listener) => {
			task.spawn(() => {
				const response = pcall(() => {
					if (listener.key === undefined || listener.key === key) {
						listener.callback(key, value, oldValue);
					}
				});
				if (!response[0]) {
					warn("A listener errored!", response[1]);
				}
			});
		});
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

		this.callListeners(key, value, oldValue);
	}

	public removeKey(key: Keyable) {
		if (this.pendingGC) return;
		const oldValue = this.storage.get(key);
		this.storage.delete(key);

		this.callListeners(key, "deleted", oldValue);
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

	public waitForValue<Valuable>(key: Keyable, secondsToWait: number = math.huge): Valuable | undefined {
		let value: Valuable | undefined = undefined;
		const heartbeat = RunService.Heartbeat.Connect((deltaTime) => {
			secondsToWait -= deltaTime;

			value = this.getValue(key);

			if (secondsToWait <= 0 || value !== undefined) heartbeat.Disconnect();
		});

		while (heartbeat.Connected && value === undefined) {
			task.wait();
		}
		return value;
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
	public addListener<T extends Valuable>(listener: Listener<T>) {
		if (this.pendingGC) return;

		const uuid = HttpService.GenerateGUID();
		this.listeners.set(uuid, listener as Listener<unknown>);

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

export class NetworkedDataObject<T extends Holdable> extends DataObject<T> {
	protected readonly uuid: string | undefined;

	protected constructor(holder: T, tags: Array<string>) {
		super(holder, tags);

		if (typeIs(holder, "Instance")) {
			this.uuid = holder.GetAttribute("uuid") as string;
		}
	}

	public static getOrConstruct<T extends Holdable>(
		holder: T,
		tags: Array<string>,
		createCallback = () => new NetworkedDataObject<T>(holder, tags),
	): NetworkedDataObject<T> {
		return super.getOrConstruct(holder, tags, createCallback) as NetworkedDataObject<T>;
	}

	public static waitFor<T extends Holdable>(
		holder: T,
		tags: Array<string>,
		secondsToWait: number = math.huge,
	): NetworkedDataObject<T> | undefined {
		const dataObject = super.waitFor(holder, tags, secondsToWait);
		if (dataObject === undefined) return undefined;
		return dataObject as NetworkedDataObject<T>;
	}

	public getInProxyForm(): HoldableProxy {
		const holder = this.getHolder();
		const tags = this.tags;
		const uuid = this.uuid;

		return { holder, tags, uuid };
	}
}

function GenerateIDForInstance(instance: Instance) {
	if (instance.GetAttribute("uuid") === undefined) {
		const uuid = HttpService.GenerateGUID(false);
		instance.SetAttribute("uuid", uuid);
		instance.AddTag(uuid);
	}
}

Workspace.DescendantAdded.Connect((instance) => GenerateIDForInstance(instance));

Workspace.GetDescendants().forEach((instance) => GenerateIDForInstance(instance));

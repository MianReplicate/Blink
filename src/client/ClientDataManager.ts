import { CollectionService, Workspace } from "@rbxts/services";
import {
	ActiveDataObjects,
	DataObject,
	Debug,
	EditFunction,
	Holdable,
	Keyable,
	ReplicatedDataObject,
	ReplicatedDataObjects,
	ReplicateEvent,
	Valuable,
} from "shared/DataManager";

const AwaitingToSync: Map<string, Map<Keyable, Valuable>> = new Map();

export namespace ClientDataManager {
	export function Init(): undefined {}
}

export class ClientDataObject<T extends Holdable> extends DataObject<T> {
	private isASyncedObject: boolean = false;

	public static construct<T extends Holdable>(holder: T, forSync?: boolean): ClientDataObject<T> {
		if (ActiveDataObjects.has(holder)) {
			return ActiveDataObjects.get(holder) as ClientDataObject<T>;
		}
		const object = new ClientDataObject<T>(holder);
		object.setIsForSyncing(forSync !== undefined ? forSync : false);
		return object;
	}

	public static waitFor<T extends Holdable>(holder: T, secondsToWait: number): ClientDataObject<T> | undefined {
		const dataObject = super.waitFor(holder, secondsToWait);
		if (dataObject === undefined) return dataObject;
		return dataObject as ClientDataObject<T>;
	}

	/**
	 * Set a key to a value. If this is a object that is currently being synced, this setValue will REQUEST the server to change the value. These will only go through if the player is allowed to change the value.
	 * @param key The key to set for this value
	 * @param value The value to store
	 * @returns Whether the set was successful
	 */
	public override setValue(key: Keyable, value: Valuable, fromServer: boolean = false): boolean {
		if (this.isPendingGC()) return false;

		if (!this.isASyncedObject || fromServer) {
			super.setValue(key, value);
			return true;
		} else {
			return EditFunction.InvokeServer(this.getHolder(), key, value);
		}
	}

	/**
	 * Get the requested value as an instance if it is a UUID
	 * @param key The key for the instance
	 * @returns The instance if this key is valid
	 */
	public getValueAsInstance(key: Keyable): Valuable {
		if (this.isPendingGC()) return;

		const value = super.getValue(key);
		return CollectionService.GetTagged(value as string)[0];
	}

	/**
	 * Set whether the data object is a synced object or not
	 * @param sync Whether this data object is synced with the server or not
	 */
	public setIsForSyncing(sync: boolean) {
		if (this.isPendingGC()) return;

		this.isASyncedObject = sync;
	}
}

ReplicateEvent.OnClientEvent.Connect((replicatedObjects: ReplicatedDataObjects) => {
	Debug("Received", replicatedObjects);

	replicatedObjects.forEach((replicatedObject) => {
		const proxy = replicatedObject.holderProxy;
		if (replicatedObject.pendingGC) {
			if (proxy.holder !== undefined) {
				const object = ActiveDataObjects.get(proxy.holder);
				object?.destroy();
			}
		} else if (replicatedObject.storage !== undefined) {
			if (proxy.holder === undefined && proxy.uuid !== undefined) {
				AwaitingToSync.set(proxy.uuid, replicatedObject.storage);
			} else {
				const dataObject = ClientDataObject.construct(proxy.holder, true);

				// if ("key" in replicatedObject) {
				// replicatedKey
				// dataObject.setValue(replicatedObject.key, replicatedObject.value);
				// } else {
				// replicatedDataObject
				replicatedObject.storage.forEach((value, key) => dataObject.setValue(key, value, true));
				// }
			}
		}
	});
});

Workspace.DescendantAdded.Connect((descendant) => {
	const uuid = descendant.GetAttribute("uuid") as string;
	if (uuid === undefined) return;
	const storageToSync = AwaitingToSync.get(uuid);
	if (storageToSync !== undefined) {
		AwaitingToSync.delete(uuid);
		const dataObject = ClientDataObject.construct(descendant, true);
		storageToSync.forEach((value, key) => dataObject.setValue(key, value, true));
	}
});

// ReplicateEvent.FireServer(); // tell the server we are ready

import { Workspace } from "@rbxts/services";
import {
	ActiveDataObjects,
	DataObject,
	Debug,
	Holdable,
	Keyable,
	ReplicatedDataObject,
	ReplicateEvent,
	Valuable,
} from "shared/DataManager";

const AwaitingToSync: Map<string, Map<Keyable, Valuable>> = new Map();

export class ClientDataObject<T extends Holdable> extends DataObject<T> {
	public static construct<T extends Holdable>(holder: T): ClientDataObject<T> {
		if (ActiveDataObjects.has(holder)) {
			return ActiveDataObjects.get(holder) as ClientDataObject<T>;
		}
		return new ClientDataObject<T>(holder);
	}

	public static waitFor<T extends Holdable>(holder: T, secondsToWait: number): ClientDataObject<T> | undefined {
		const dataObject = super.waitFor(holder, secondsToWait);
		if (dataObject === undefined) return dataObject;
		return dataObject as ClientDataObject<T>;
	}
}

ReplicateEvent.OnClientEvent.Connect((replicatedObject: ReplicatedDataObject) => {
	Debug("Received", replicatedObject.holderProxy, replicatedObject.storage);

	const proxy = replicatedObject.holderProxy;
	if (proxy.holder === undefined && proxy.uuid !== undefined) {
		AwaitingToSync.set(proxy.uuid, replicatedObject.storage);
	} else {
		const dataObject = ClientDataObject.construct(proxy.holder);

		// if ("key" in replicatedObject) {
		// replicatedKey
		// dataObject.setValue(replicatedObject.key, replicatedObject.value);
		// } else {
		// replicatedDataObject
		replicatedObject.storage.forEach((value, key) => dataObject.setValue(key, value));
		// }
	}
});

Workspace.DescendantAdded.Connect((descendant) => {
	const uuid = descendant.GetAttribute("uuid") as string;
	if (uuid === undefined) return;
	const storageToSync = AwaitingToSync.get(uuid);
	if (storageToSync !== undefined) {
		AwaitingToSync.delete(uuid);
		const dataObject = ClientDataObject.construct(descendant);
		storageToSync.forEach((value, key) => dataObject.setValue(key, value));
	}
});

// ReplicateEvent.FireServer(); // tell the server we are ready

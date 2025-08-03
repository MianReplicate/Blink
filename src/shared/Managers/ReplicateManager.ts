import { ReplicatedStorage } from "@rbxts/services";
import { Holdable, Keyable, Valuable } from "./DataManager";

export type HoldableProxy = { holder: Holdable; tags: ReadonlyArray<string>; uuid: string | undefined };

export enum ReplicateType {
	Unreliable,
	Reliable,
}
export type ReplicatedDataObjects = Array<ReplicatedDataObject>;
export type ReplicatedDataObject = {
	holderProxy: HoldableProxy;
	pendingGC: boolean;
	dirtyKeys: Map<Keyable, Valuable> | undefined;
};

export const ReplicateEvent =
	(ReplicatedStorage.FindFirstChild("ReplicateEvent") as RemoteEvent) || new Instance("RemoteEvent");
ReplicateEvent.Name = "ReplicateEvent";
ReplicateEvent.Parent = ReplicatedStorage;

export const UnreliableReplicateEvent =
	(ReplicatedStorage.FindFirstChild("UnreliableReplicateEvent") as UnreliableRemoteEvent) ||
	new Instance("UnreliableRemoteEvent");
UnreliableReplicateEvent.Name = "UnreliableReplicateEvent";
UnreliableReplicateEvent.Parent = ReplicatedStorage;

export const EditFunction =
	(ReplicatedStorage.FindFirstChild("EditFunction") as RemoteFunction) || new Instance("RemoteFunction");
EditFunction.Name = "EditFunction";
EditFunction.Parent = ReplicatedStorage;

export function ReplicateToPlayer(player: Player, toReplicate: ReplicatedDataObjects, replicateType: ReplicateType) {
	if (replicateType === ReplicateType.Reliable) {
		ReplicateEvent.FireClient(player, toReplicate);
	} else {
		UnreliableReplicateEvent.FireClient(player, toReplicate);
	}
}

export function SendServerNewValue(holderProxy: HoldableProxy, key: Keyable, value: Valuable) {
	return EditFunction.InvokeServer(holderProxy, key, value);
}

import { ReplicatedStorage } from "@rbxts/services";
import { Holdable, Keyable, Valuable } from "./DataManager";

export type HoldableProxy = { holder: Holdable; tags: ReadonlyArray<string>; uuid: string | undefined };

export type ReplicatedDataObjects = Array<ReplicatedDataObject>;
export type ReplicatedDataObject = {
	holderProxy: HoldableProxy;
	pendingGC: boolean;
	storage: Map<Keyable, Valuable> | undefined;
};

export const ReplicateEvent =
	(ReplicatedStorage.FindFirstChild("ReplicateEvent") as RemoteEvent) || new Instance("RemoteEvent");
ReplicateEvent.Name = "ReplicateEvent";
ReplicateEvent.Parent = ReplicatedStorage;

export const EditFunction =
	(ReplicatedStorage.FindFirstChild("EditFunction") as RemoteFunction) || new Instance("RemoteFunction");
EditFunction.Name = "EditFunction";
EditFunction.Parent = ReplicatedStorage;

export function ReplicateToPlayer(player: Player, toReplicate: ReplicatedDataObjects) {
	ReplicateEvent.FireClient(player, toReplicate);
}

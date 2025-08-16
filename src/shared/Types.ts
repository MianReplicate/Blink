import { ReplicatedStorage } from "@rbxts/services";

export const RoleAction: RemoteFunction =
	(ReplicatedStorage.FindFirstChild("RoleAction") as RemoteFunction) || new Instance("RemoteFunction");
RoleAction.Name = "RoleAction";
RoleAction.Parent = ReplicatedStorage;

export const RoleRemoval: RemoteEvent =
	(ReplicatedStorage.FindFirstChild("RoleRemoval") as RemoteEvent) || new Instance("RemoteEvent");
RoleRemoval.Name = "RoleRemoval";
RoleRemoval.Parent = ReplicatedStorage;

export enum ActorType {
	Survivor = "Survivor",
	// Angel = "Angel",
}

export type ActionType = "Blink" | "Strain";

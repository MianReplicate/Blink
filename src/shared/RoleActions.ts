import { ReplicatedStorage, RunService } from "@rbxts/services";

export const RoleAction: RemoteFunction =
	(ReplicatedStorage.FindFirstChild("RoleAction") as RemoteFunction) || new Instance("RemoteFunction");
RoleAction.Name = "RoleAction";
RoleAction.Parent = ReplicatedStorage;

export type ActionType = "Blink" | "Strain";

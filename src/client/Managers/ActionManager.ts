import { UserInputService } from "@rbxts/services";
import { ActionType, RoleAction } from "shared/Types";

export namespace ActionManager {
	export function callAction(actionName: ActionType) {
		RoleAction.InvokeServer(actionName);
	}
}

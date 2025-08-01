import { UserInputService } from "@rbxts/services";
import { ActionType, RoleAction } from "shared/RoleActions";

export namespace ActionManager {
	export function callAction(actionName: ActionType) {
		RoleAction.InvokeServer(actionName);
	}
}

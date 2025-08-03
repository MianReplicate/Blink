import { UserInputService } from "@rbxts/services";
import { ActionManager } from "./ActionManager";
import { ActionType } from "shared/Types";

const KeyMap = new Map<Enum.KeyCode, Callback>();

export namespace ControlManager {
	export function bind(guiObject: GuiObject, action: ActionType): undefined;
	export function bind(guiObject: GuiObject, callback: Callback): undefined;
	export function bind(keyCode: Enum.KeyCode, action: ActionType): undefined;
	export function bind(keyCode: Enum.KeyCode, callback: Callback): undefined;

	export function bind(object: unknown, actionCallback: unknown): undefined {
		if (typeOf(object) === "EnumItem") {
			if (typeIs(actionCallback, "string")) {
				KeyMap.set(object as Enum.KeyCode, () => ActionManager.callAction(actionCallback as ActionType));
			} else {
				KeyMap.set(object as Enum.KeyCode, actionCallback as Callback);
			}
		} else {
			const guiObject = object as GuiObject;
			const callback = typeIs(actionCallback, "string")
				? () => ActionManager.callAction(actionCallback as ActionType)
				: (actionCallback as Callback);

			guiObject.TouchTap.Connect(callback);
		}
	}
}

UserInputService.InputBegan.Connect((input, gpe) => {
	if (!gpe) {
		const callback = KeyMap.get(input.KeyCode);
		if (callback !== undefined) {
			callback();
		}
	}
});

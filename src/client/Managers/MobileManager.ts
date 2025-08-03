import { UserInputService } from "@rbxts/services";

const UI: Array<GuiObject> = new Array();

function TouchChanged() {
	const touchEnabled = UserInputService.TouchEnabled;
	UI.forEach((object) => (object.Visible = touchEnabled));
}

export namespace MobileManager {
	export function add(ui: GuiObject) {
		UI.push(ui);
		TouchChanged();
	}
}

UserInputService.GetPropertyChangedSignal("TouchEnabled").Connect(TouchChanged);

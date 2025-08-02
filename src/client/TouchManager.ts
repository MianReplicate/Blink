import { UserInputService } from "@rbxts/services";

const UI: Array<Frame> = new Array();

function TouchChanged() {
	const touchEnabled = UserInputService.TouchEnabled;
	UI.forEach((frame) => (frame.Visible = touchEnabled));
}

export function AddTouchUI(ui: Frame) {
	UI.push(ui);
	TouchChanged();
}

UserInputService.GetPropertyChangedSignal("TouchEnabled").Connect(TouchChanged);

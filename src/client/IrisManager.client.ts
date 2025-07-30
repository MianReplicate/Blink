import Iris from "@rbxts/iris";
import { WindowArguments } from "@rbxts/iris/src/lib/widgets/window";
import { DataManager, DataObject } from "shared/DataManager";
import { Players, UserInputService } from "@rbxts/services";
import { ClientDataManager, ClientDataObject } from "./ClientDataManager";
import { Object, String } from "@rbxts/luau-polyfill";

ClientDataManager.Init();

let isVisible = false;
let wasLockedInFirstPerson = false;

Iris.Init();
Iris.Connect(() => {
	if (isVisible) {
		const window = Iris.Window(
			["Data Viewer: F6 to hide/open window; F7 to unlock/lock mouse", undefined, undefined, undefined, true],
			{
				size: Iris.State(new Vector2(500, 500)),
			},
		);

		if (window.state.isOpened.get() && window.state.isUncollapsed.get()) {
			const input = Iris.InputText([undefined, "Search"]);
			const inputText = input.state.text.get().lower();

			DataManager.getObjects().forEach((dataObject) => {
				const holder = dataObject.getHolder();
				const tags = dataObject.getTags();
				const isInstance = typeIs(holder, "Instance");
				let name = isInstance ? holder.Name : tostring(holder);

				name += " [";
				for (let i = 0; i < tags.size(); i++) {
					name += tags[i];
					if (tags.size() - i !== 1) {
						name += ", ";
					} else {
						name += "]";
					}
				}

				if (inputText.size() === 0 || String.includes(name.lower(), inputText)) {
					const objectTree = Iris.Tree([name]);

					if (objectTree.state.isUncollapsed.get()) {
						// Iris.Text(["Name: " + name]);
						Iris.Text(["Is Instance: " + isInstance]);

						const storageTree = Iris.Tree(["Storage"]);

						if (storageTree.state.isUncollapsed.get()) {
							dataObject.getStorage().forEach((value, key) => {
								Iris.Text([key + ": " + value]);
							});
						}

						Iris.End();
					}

					Iris.End();
				}
			});
		}
		Iris.End();
	}
});

UserInputService.InputEnded.Connect((input, gameProcessedEvent) => {
	if (input.KeyCode === Enum.KeyCode.F6) {
		isVisible = !isVisible;
	} else if (input.KeyCode === Enum.KeyCode.F7) {
		if (UserInputService.MouseBehavior === Enum.MouseBehavior.Default) {
			if (wasLockedInFirstPerson) {
				Players.LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson;
			}
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter;
		} else {
			if (Players.LocalPlayer.CameraMode === Enum.CameraMode.LockFirstPerson) {
				Players.LocalPlayer.CameraMode = Enum.CameraMode.Classic;
				wasLockedInFirstPerson = true;
			}
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default;
		}
	}
});

Players.LocalPlayer.CharacterAdded.Connect((character) => (wasLockedInFirstPerson = false));

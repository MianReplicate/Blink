import Iris from "@rbxts/iris";
import { WindowArguments } from "@rbxts/iris/src/lib/widgets/window";
import { DataManager, DataObject } from "shared/DataManager";
import { Players, UserInputService } from "@rbxts/services";
import { ClientDataManager, ClientDataObject } from "./ClientDataManager";

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
			Iris.Text(["Now see, that's kinda cool, don't ya think?"]);

			DataManager.getDataObjects().forEach((dataObject) => {
				const holder = dataObject.getHolder();
				const isInstance = typeIs(holder, "Instance");
				const name = isInstance ? holder.Name : holder;
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

import Iris from "@rbxts/iris";
import { WindowArguments } from "@rbxts/iris/src/lib/widgets/window";
import { DataManager, Holdable, Keyable, Valuable } from "shared/Managers/DataManager";
import { Players, UserInputService } from "@rbxts/services";
import { ClientDataManager, ClientDataObject } from "./ClientDataObject";
import { Object, String } from "@rbxts/luau-polyfill";
import { EditFunction, HoldableProxy } from "shared/Managers/ReplicateManager";

ClientDataManager.Init();

type ValidTypes = number | string | boolean;

abstract class Editable<T extends ValidTypes> {
	abstract convertFrom(stringVariant: string): T | undefined;
}

class ENumber extends Editable<number> {
	public convertFrom(stringVariant: string): number | undefined {
		return tonumber(stringVariant);
	}
}

class EString extends Editable<string> {
	public convertFrom(stringVariant: string): string | undefined {
		return tostring(stringVariant);
	}
}

class EBoolean extends Editable<boolean> {
	public convertFrom(stringVariant: string): boolean | undefined {
		const lower = stringVariant.lower();
		if (lower === "false") return false;
		if (lower === "true") return true;
	}
}

const EditableTypes: Map<keyof CheckableTypes, Editable<ValidTypes>> = new Map();
EditableTypes.set("number", new ENumber());
EditableTypes.set("string", new EString());
EditableTypes.set("boolean", new EBoolean());

const editProperties: {
	editing: boolean;
	currentClass: Editable<ValidTypes> | undefined;
	dataObject: ClientDataObject<Holdable> | undefined;
	key: Keyable | undefined;
	value: Valuable;
} = {
	editing: false,
	currentClass: undefined,
	dataObject: undefined,
	key: undefined,
	value: undefined,
};

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

		if (editProperties.editing) {
			Iris.Text(["Editing " + tostring(editProperties.key)]);
			const input = Iris.InputText([tostring(editProperties.value), "Value"]);
			const done = Iris.Button(["Done"]);
			const cancel = Iris.Button(["Cancel"]);

			if (cancel.clicked()) {
				editProperties.editing = false;
				editProperties.currentClass = undefined;
				editProperties.dataObject = undefined;
				editProperties.key = undefined;
				editProperties.value = undefined;
			}

			if (done.clicked()) {
				editProperties.editing = false;

				task.spawn((...args) => {
					editProperties.dataObject?.setValue(
						editProperties.key as Keyable,
						editProperties.currentClass?.convertFrom(input.state.text.get()),
					);
				});

				editProperties.currentClass = undefined;
				editProperties.dataObject = undefined;
				editProperties.key = undefined;
				editProperties.value = undefined;
			}
		} else {
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
									const classEdit = EditableTypes.get(typeOf(value));
									if (classEdit !== undefined && value !== "unreplicated") {
										const button = Iris.Button([key + ": " + value]);

										if (button.clicked()) {
											editProperties.editing = true;
											editProperties.currentClass = classEdit;
											editProperties.dataObject = dataObject as ClientDataObject<Holdable>;
											editProperties.key = key;
											editProperties.value = value;
										}
									} else {
										Iris.Text([key + ": " + value]);
									}
								});
							}

							Iris.End();
						}

						Iris.End();
					}
				});
			}
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

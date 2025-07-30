// import { makeHello } from "shared/module";

import { Players, Workspace } from "@rbxts/services";
import { ClientDataObject } from "./ClientDataManager";

// print(makeHello("main.client.ts"));

// const object = ClientDataObject.waitFor(Workspace.WaitForChild("Baseplate"), 5);
// print(object?.getValue("grr"));
// task.wait(3);
// print("Requesting edit!");
// print(object?.setValue("hello", false));

const survivor = ClientDataObject.waitFor(Players.WaitForChild("MianReplicate"), 5);
survivor?.addListener({ callback: (key, value, oldValue) => print(key, value, oldValue) });

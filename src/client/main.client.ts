// import { makeHello } from "shared/module";

import { Workspace } from "@rbxts/services";
import { ClientDataObject } from "./ClientDataManager";

// print(makeHello("main.client.ts"));

const object = ClientDataObject.waitFor(Workspace.WaitForChild("Baseplate"), 2);
// print(object?.getValue("grr"));

import { Workspace } from "@rbxts/services";
import { ServerDataObject } from "./ServerDataManager";

const dataObject = ServerDataObject.waitFor(Workspace.WaitForChild("Baseplate"), 2);

// if (dataObject !== undefined) {
// 	print("Found!");
// 	print(dataObject.getValue("grr"));
// } else {
// 	print("nto found :(");
// }

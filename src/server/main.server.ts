import { Players, Workspace } from "@rbxts/services";
import { DataObject } from "shared/DataCreator";
import { makeHello } from "shared/module";
import { ServerDataObject } from "./ServerDataCreator";

task.wait(5);
const newData = ServerDataObject.construct<Instance>(Workspace.WaitForChild("Baseplate"));
print("Created!");
// newData.addListener("newValue", (key, value, oldValue) => print(key, value, oldValue));
// newData.replicateKeyTo("grr", ["tag", Players.WaitForChild("MianReplicate") as Player]);

newData.setValue("grr", "Is that a dog?");

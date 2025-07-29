import { Players, Workspace } from "@rbxts/services";
import { DataObject } from "shared/DataManager";
import { makeHello } from "shared/module";
import { ServerDataObject } from "./ServerDataManager";

for (let i = 0; i < 100; i++) {
	const newData = ServerDataObject.construct<string>("" + i);
	newData.replicateKeysTo(["test", "test1", "test2"], ["default"]);

	task.spawn((...args) => {
		// while (task.wait()) {
		newData.setValue("test", math.random());
		newData.setValue("test1", math.random());
		newData.setValue("test2", math.random());
		// }
	});
}

// newData.addListener("newValue", (key, value, oldValue) => print(key, value, oldValue));
// newData.replicateKeyTo("grr", ["tag", Players.WaitForChild("MianReplicate") as Player]);

// while (task.wait()) {
// 	newData.setValue("grr", math.random());
// }

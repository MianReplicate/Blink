import { Players, Workspace } from "@rbxts/services";
import { DataObject, Valuable } from "shared/DataManager";
import { makeHello } from "shared/module";
import { ServerDataObject } from "./ServerDataManager";

const newData = ServerDataObject.construct<Instance>(Workspace.WaitForChild("Baseplate"));
newData.setCriteriaForDataObject(() => true);
newData.setPlayerCriteriaForKey("health", (player) => {
	return { canSeeKey: false, canSeeValue: true, canEditValue: true };
});

newData.setValue("health", 100);

class Survivor {
	private data: ServerDataObject<Instance>;

	constructor(player: Player) {
		this.data = ServerDataObject.construct(player);

		// this.data.setReplicateCriteriaForKey("health", ["default"]);
		this.data.addListener({
			callback: (key, value, oldValue) => {
				print(key, value, oldValue);
			},
		});
		this.data.setValue("health", 100);
	}
}

Players.PlayerAdded.Connect((player) => new Survivor(player));

// newData.setReplicateCriteriaForKey("health", ["default"]);
// task.wait(2);
// newData.setValue("health", { health: 100, maxHealth: 100 });
// newData.setValue("health", { health: 50, maxHealth: 100 });
// task.wait(1);
// newData.destroy();
// newData.setReplicateCriteriaForKey("hello", ["default"]);
// newData.setEditorCriteriaForKey("hello", ["default"]);
// newData.addListener("hello", (key, value) => print(key, value));
// newData.setValue("hello", true);

// for (let i = 0; i < 10; i++) {
// 	const newData = ServerDataObject.construct<string>("" + i);
// 	newData.setReplicateCriteriaForKeys(["test", "test1", "test2", "test3"], ["default"]);

// 	task.spawn((...args) => {
// 		while (task.wait()) {
// 			newData.setValue("test", math.random());
// 			newData.setValue("test1", math.random());
// 			newData.setValue("test2", math.random());
// 			newData.setValue("test3", Workspace.Baseplate);
// 		}
// 	});
// }

// newData.addListener("newValue", (key, value, oldValue) => print(key, value, oldValue));
// newData.replicateKeyTo("grr", ["tag", Players.WaitForChild("MianReplicate") as Player]);

// while (task.wait()) {
// 	newData.setValue("grr", math.random());
// }

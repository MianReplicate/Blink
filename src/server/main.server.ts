import { Players, Workspace } from "@rbxts/services";
import { DataManager, DataObject, Valuable } from "shared/DataManager";
import { makeHello } from "shared/module";
import { ServerDataObject } from "./ServerDataManager";

Players.PlayerAdded.Connect((player) => {
	const survivor = ServerDataObject.getOrConstruct<Instance>(player, ["Survivor", "Angel"]);
	const playerData = ServerDataObject.getOrConstruct<Instance>(player, ["Player"]);

	const predicate = (plr: Player) => plr.UserId === player.UserId;

	survivor.setCriteriaForDataObject(predicate);
	playerData.setCriteriaForDataObject(predicate);

	survivor.setPlayerCriteriaForKeys(["health", "blinkMeter"], (plr) => {
		if (predicate(plr)) {
			return { canSeeKey: true, canSeeValue: true, canEditValue: false };
		}
		return { canSeeKey: false, canSeeValue: false, canEditValue: false };
	});

	playerData.setPlayerCriteriaForKeys(["coins"], (plr) => {
		if (predicate(plr)) {
			return { canSeeKey: true, canSeeValue: true, canEditValue: false };
		}
		return { canSeeKey: false, canSeeValue: false, canEditValue: false };
	});

	task.wait(2);
	survivor.setValue("health", 50);
	survivor.setValue("blinkMeter", 10);

	playerData.setValue("coins", 10);
});

// const survivor = ServerDataObject.getOrConstruct<Instance>(Workspace.WaitForChild("Baseplate"), ["Angel"]);
// const player = ServerDataObject.getOrConstruct<Instance>(Workspace.WaitForChild("Baseplate"), [
// 	"Player",
// 	"Health",
// ]);

// print(DataManager.getDataObject(Workspace.Baseplate, ["Angel"]));
// print(DataManager.getDataObject(Workspace.Baseplate, ["Angel", "Health"]));
// newData.setCriteriaForDataObject(() => true);
// newData.setPlayerCriteriaForKey("health", (player) => {
// 	return { canSeeKey: false, canSeeValue: true, canEditValue: true };
// });

// class Survivor {
// 	private data: ServerDataObject<Instance>;

// 	constructor(player: Player) {
// 		this.data = ServerDataObject.getOrConstruct(player);

// 		// this.data.setReplicateCriteriaForKey("health", ["default"]);
// 		this.data.addListener({
// 			callback: (key, value, oldValue) => {
// 				print(key, value, oldValue);
// 			},
// 		});
// 		// this.data.setValue("health", 100);
// 	}
// }

// Players.PlayerAdded.Connect((player) => new Survivor(player));

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

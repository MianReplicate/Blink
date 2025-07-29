import { Players, Workspace } from "@rbxts/services";
import { DataObject, Valuable } from "shared/DataManager";
import { makeHello } from "shared/module";
import { ServerDataObject } from "./ServerDataManager";

// let d = 1;
// const d = "daw";

// Workspace.Baseplate.Touched.Connect((otherPart) => {
// 	print(otherPart);
// });

// print("d");

class Actor{
    private readonly player: Player;

    constructor(player: Player){
        this.player = player;
    }

    public getPlayer(){
        return this.player;
    }
}

class Survivor extends Actor{

    public blink(){

    }
}

class Angel extends Actor{

    public flicker(){
        print("flicker");
    }
}

Players.PlayerAdded.Connect((player) => {
    const angel = new Angel(player);
    const survivor = new Survivor(player);

    survivor.getPlayer();
    angel.getPlayer();
    
    survivor.blink();
    angel.flicker();
})

// const newData = ServerDataObject.construct<Instance>(Workspace.WaitForChild("Baseplate"));
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

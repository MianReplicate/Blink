import { Workspace } from "@rbxts/services";
import { ServerDataObject } from "server/ServerDataObject";

const ragdollList = ServerDataObject.getOrConstruct<string>("List", ["Ragdoll"]);

export namespace ObjectManager {
	export function removeRagdolls() {
		ragdollList.wipeStorage(true);
	}

	export function createRagdoll(character: Model): Model {
		const humanoid = character.FindFirstChildOfClass("Humanoid");
		if (humanoid) humanoid.Health = 0;
		const clone = character.Clone() as Model;
		clone
			.GetDescendants()
			.filter((value) => value.IsA("BaseScript"))
			.forEach((value) => value.Destroy());
		clone.Parent = Workspace;
		clone.Name = "Ragdoll";

		character.Destroy();

		clone
			.GetDescendants()
			.filter((value) => value.IsA("BasePart"))
			.forEach((value) => (value.CollisionGroup = "Ragdolls"));

		ragdollList.addValue(clone);

		return clone;
	}
}

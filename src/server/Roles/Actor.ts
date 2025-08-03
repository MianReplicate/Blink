import { PlayerKeyPredicate, ServerDataObject } from "server/ServerDataObject";
import { Replicatable } from "shared/Managers/DataManager";
import { TickManager } from "shared/Managers/TickManager";
import { ActorType } from "shared/Types";

export abstract class Actor implements Replicatable {
	replicatable: boolean = false;
	protected data: ServerDataObject<Instance>;
	private actorType: ActorType;

	protected constructor(data: ServerDataObject<Instance>, actorType: ActorType) {
		this.data = data;
		this.actorType = actorType;

		this.data
			.getHolder()
			.GetDescendants()
			.filter((value) => value.IsA("BasePart"))
			.forEach((value) => (value.CollisionGroup = "Characters"));
	}

	public setPlayer(player: Player): void {
		this.data.setValue("player", player);
	}

	public die(): void {
		this.data.setValue("dead", true);
	}

	public destroy(): void {
		this.data.destroy();
	}

	public tick(): void {
		const humanoid = this.data.getHolder().FindFirstChild("Humanoid") as Humanoid;
		if (humanoid === undefined) {
			ServerDataObject.getOrConstruct<string>("List", [this.actorType]).removeKey(this.data.getHolder());
			TickManager.runNextTick(() => this.destroy());
		} else if (humanoid.Health <= 0) this.die();
	}

	public getData() {
		return this.data;
	}
}

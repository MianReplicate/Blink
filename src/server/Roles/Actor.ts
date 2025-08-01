import { ServerDataObject } from "server/ServerDataObject";
import { Replicatable } from "shared/DataManager";

export abstract class Actor implements Replicatable {
	replicatable: boolean = false;
	protected data: ServerDataObject<Instance>;

	protected constructor(data: ServerDataObject<Instance>) {
		this.data = data;
	}

	public die(): void {
		this.data.setValue("dead", true);
	}

	public destroy(): void {
		this.data.destroy();
	}

	public tick(): void {
		const humanoid = this.data.getHolder().FindFirstChild("Humanoid") as Humanoid;
		if (humanoid === undefined) this.destroy();
		else if (humanoid.Health <= 0) this.die();
	}

	public getData() {
		return this.data;
	}
}

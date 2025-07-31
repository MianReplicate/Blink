import { ServerDataObject } from "server/ServerDataManager";
import { Replicatable } from "shared/DataManager";

export abstract class Actor implements Replicatable {
	replicatable: boolean = false;
	protected data: ServerDataObject<Instance>;

	protected constructor(data: ServerDataObject<Instance>) {
		this.data = data;
	}

	abstract die(): void;
	abstract destroy(): void;
	public tick(): void {
		const humanoid = this.data.getHolder().FindFirstChild("Humanoid") as Humanoid;
		if (humanoid === undefined) this.destroy();
		else if (humanoid.Health <= 0) this.die();
	}

	public getData() {
		return this.data;
	}
}

import { ServerDataObject } from "server/ServerDataManager";
import { Replicatable } from "shared/DataManager";

export abstract class Actor implements Replicatable {
	replicatable: boolean = false;
	protected data: ServerDataObject<Instance>;

	constructor(data: ServerDataObject<Instance>) {
		this.data = data;
	}

	abstract die(): void;

	public getData() {
		return this.data;
	}
}

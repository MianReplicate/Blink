import { DataManager } from "../shared/DataManager";
import { Survivor } from "./Roles/Survivor";
import { ServerDataObject } from "./ServerDataManager";

const survivorList = ServerDataObject.getOrConstruct<string>("List", ["Survivor"]);

survivorList.setCriteriaForDataObject((plr) => true);
survivorList.setFutureCriteriaForKeys((plr) => {
	return { canSeeKey: true, canSeeValue: false, canEditValue: false };
});

export namespace GameLibrary {
	export function getSurvivors() {
		return DataManager.getTagged(["Survivor"]);
	}

	export function getAngels() {
		return DataManager.getTagged(["Angel"]);
	}

	export function createOrGetSurvivor(character: Model, player?: Player): Survivor {
		let survivor = survivorList.getValue<Survivor>(character);
		if (survivor !== undefined) return survivor;

		survivor = new Survivor(character);
		survivorList.setValue(character, survivor);

		return survivor;
	}
}

// Survivor;

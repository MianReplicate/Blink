import { DataManager, Keyable } from "../shared/DataManager";
import { Actor } from "./Roles/Actor";
import { Survivor, SurvivorList } from "./Roles/Survivor";
import { ServerDataObject } from "./ServerDataObject";

export enum ActorType {
	Survivor,
	// Angel,
}

export namespace GameHelper {
	export function getSurvivors() {
		return SurvivorList.getStorage() as Map<Keyable, Survivor>;
	}

	// export function getAngels() {
	// 	return DataManager.getTagged(["Angel"]);
	// }

	// export function createOrGetSurvivor(character: Model, player?: Player): Survivor {
	// 	let survivor = survivorList.getValue<Survivor>(character);
	// 	if (survivor !== undefined) return survivor;

	// 	survivor = new Survivor(character);
	// 	survivorList.setValue(character, survivor);

	// 	return survivor;
	// }

	// export function createActor<T extends Actor>(classType: T, character: Model, player?: Player): T {}

	export function getRoleData(character: Model): Actor | undefined {
		const survivor = getSurvivors().get(character);

		return survivor;
	}

	export function changeIntoRole(actorType: ActorType, player: Player): Actor {
		const character = player.Character;
		if (character !== undefined) {
			const currentData = getRoleData(character);
			currentData?.destroy();
		}

		switch (actorType) {
			case ActorType.Survivor:
				player.LoadCharacter();
				return Survivor.getOrCreate(player.Character as Model, player);
			// case ActorType.Angel:
			// const randomAngel = WeepingAngels.GetChildren()[math.random(1, #WeepingAngels:GetChildren())]:Clone()
			// player.Character = randomAngel
			// randomAngel.Parent = workspace
			// return randomAngel
		}
	}
}

// Survivor;

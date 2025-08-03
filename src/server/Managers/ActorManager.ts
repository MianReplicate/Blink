import { PhysicsService } from "@rbxts/services";
import { DataManager, Keyable } from "../../shared/Managers/DataManager";
import { Actor } from "../Roles/Actor";
import { Survivor } from "../Roles/Survivor";
import { ServerDataObject } from "../ServerDataObject";
import { Object, String } from "@rbxts/luau-polyfill";
import { ActorType } from "shared/Types";

const actorTypes = Object.values(ActorType);
actorTypes.forEach((actorType) => {
	const list = ServerDataObject.getOrConstruct<string>("List", [actorType]);
	list.setCriteriaForDataObject(() => true);
	list.setFutureCriteriaForKeys(() => {
		return { canSeeKey: true, canSeeValue: false, canEditValue: false };
	});
});

export const RagdollGroup = PhysicsService.RegisterCollisionGroup("Ragdolls");
export const CharacterGroup = PhysicsService.RegisterCollisionGroup("Characters");
PhysicsService.CollisionGroupSetCollidable("Ragdolls", "Characters", false);

export namespace ActorManager {
	export function getActorsOf<T extends Actor>(actorType: ActorType) {
		return ServerDataObject.getOrConstruct<string>("List", [actorType]).getStorage() as Map<Keyable, T>;
	}

	export function getRoleData(character: Model): Actor | undefined {
		const survivor = getActorsOf<Survivor>(ActorType.Survivor).get(character);

		return survivor;
	}

	export function createRole(actorType: ActorType, character: Model): Actor {
		const list = ServerDataObject.getOrConstruct<string>("List", [actorType]);
		let roleData = list.getValue<Actor>(character);
		if (roleData !== undefined) return roleData;

		switch (actorType) {
			case ActorType.Survivor:
				roleData = new Survivor(character);
		}

		list.setValue(character, roleData);
		return roleData;
	}

	export function changeIntoRole(actorType: ActorType, player: Player): Actor {
		let character = player.Character;
		if (character !== undefined) {
			const currentData = getRoleData(character);
			currentData?.destroy();
		}

		let role = undefined;
		switch (actorType) {
			case ActorType.Survivor:
				player.LoadCharacter();
				character = player.Character || player.CharacterAdded.Wait()[0];

				role = createRole(actorType, character);
				role.setPlayer(player);
		}

		return role;
	}
}

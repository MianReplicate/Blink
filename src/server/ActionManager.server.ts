import { GameHelper } from "server/GameHelper";
import { ActionType, RoleAction } from "shared/RoleActions";
import { Actor } from "./Roles/Actor";
import { Survivor } from "./Roles/Survivor";

abstract class Action {
	protected readonly role: Actor;

	constructor(role: Actor) {
		this.role = role;
	}

	abstract execute(): boolean;
}

namespace Actions {
	export class Blink extends Action {
		public execute() {
			if (this.role instanceof Survivor) {
				return this.role.blink();
			}
			return false;
		}
	}

	export class Strain extends Action {
		public execute() {
			if (this.role instanceof Survivor) {
				return this.role.strain();
			}
			return false;
		}
	}
}

RoleAction.OnServerInvoke = (player, action: unknown) => {
	const character = player.Character;
	if (character) {
		const role = GameHelper.getRoleData(character);
		if (role) {
			const actionClass = new Actions[action as keyof typeof Actions](role);
			return actionClass.execute();
		}
	}
	return false;
};

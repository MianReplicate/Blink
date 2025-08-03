import { ActorManager } from "./Managers/ActorManager";
import { TickManager } from "shared/Managers/TickManager";
import { ActionManager } from "./Managers/ActionManager";
import { Survivor } from "./Roles/Survivor";
import { ActorType } from "shared/Types";

ActionManager.init();

// GameLibrary.createOrGetSurvivor(Workspace.Baseplate);

// TickManager.addTickable("Angels");
TickManager.addTickable("[Survivors]", (deltaTime) =>
	ActorManager.getActorsOf<Survivor>(ActorType.Survivor).forEach((survivor) => survivor.tick()),
);
// TickManager.addTickable("Lights");

import { ActorManager } from "./Managers/ActorManager";
import { TickManager } from "shared/Managers/TickManager";
import { ActionManager } from "./Managers/ActionManager";

ActionManager.init();

// GameLibrary.createOrGetSurvivor(Workspace.Baseplate);

// TickManager.addTickable("Angels");
TickManager.addTickable("[Survivors]", (deltaTime) =>
	ActorManager.getSurvivors().forEach((survivor) => survivor.tick()),
);
// TickManager.addTickable("Lights");

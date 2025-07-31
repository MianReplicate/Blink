import { TickManager } from "shared/TickManager";
import { Survivor } from "./Roles/Survivor";
import { Workspace } from "@rbxts/services";
import { GameLibrary } from "./GameLibrary";

GameLibrary.createOrGetSurvivor(Workspace.Baseplate);

// TickManager.addTickable("Angels");
// TickManager.addTickable("Survivors", (deltaTime) => {});
// TickManager.addTickable("Lights");

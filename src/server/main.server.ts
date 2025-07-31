import { TickManager } from "shared/TickManager";
import { Survivor } from "./Roles/Survivor";
import { Workspace } from "@rbxts/services";
import { GameHelper } from "./GameLibrary";
import { ServerDataObject } from "./ServerDataManager";
import { ReplicateType } from "shared/ReplicateManager";

// GameLibrary.createOrGetSurvivor(Workspace.Baseplate);

// TickManager.addTickable("Angels");
TickManager.addTickable("Survivors", (deltaTime) => GameHelper.getSurvivors().forEach((survivor) => survivor.tick()));
// TickManager.addTickable("Lights");

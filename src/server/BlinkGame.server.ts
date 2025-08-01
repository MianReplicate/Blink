import { TickManager } from "shared/TickManager";
import { Survivor } from "./Roles/Survivor";
import { Workspace } from "@rbxts/services";
import { GameHelper } from "./GameHelper";
import { ServerDataObject } from "./ServerDataObject";
import { ReplicateType } from "shared/ReplicateManager";
import { RoleAction } from "shared/RoleActions";
import { Actor } from "./Roles/Actor";

// GameLibrary.createOrGetSurvivor(Workspace.Baseplate);

// TickManager.addTickable("Angels");
TickManager.addTickable("[Survivors]", (deltaTime) => GameHelper.getSurvivors().forEach((survivor) => survivor.tick()));
// TickManager.addTickable("Lights");

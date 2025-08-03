import { Object } from "@rbxts/luau-polyfill";
import { RunService } from "@rbxts/services";

type Tickable = (deltaTime: number) => void;

let ticking = true;

const ToTick = new Map<string, Tickable>();
const TempToTick = new Array<Tickable>();
let ToTickEntries = new Array<[string, Tickable]>();

export namespace TickManager {
	export function addTickable(name: string, tickable: Tickable) {
		ToTick.set(name, tickable);
		ToTickEntries = Object.entries(ToTick);

		print("Added " + name + " for ticking");
	}

	export function setTicking(start: boolean) {
		ticking = start;
	}

	export function runNextTick(toRun: Tickable) {
		TempToTick.push(toRun);
	}
}

RunService.Heartbeat.Connect((deltaTime) => {
	// end is highest priority (runs first), beginning is lowest priority (runs last)
	if (ticking) {
		for (let i = ToTickEntries.size() - 1; i >= 0; i--) {
			ToTickEntries[i][1](deltaTime);
		}

		TempToTick.forEach((tick) => tick(deltaTime));
		TempToTick.clear();
	}
});

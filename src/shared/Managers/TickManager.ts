import { Object } from "@rbxts/luau-polyfill";
import { RunService } from "@rbxts/services";

type Tickable = (deltaTime: number) => void;

let ticking = true;

export namespace TickManager {
	const ToTick = new Map<string, Tickable>();
	export let ToTickEntries = new Array<[string, Tickable]>();

	export function addTickable(name: string, tickable: Tickable) {
		ToTick.set(name, tickable);
		ToTickEntries = Object.entries(ToTick);

		print("Added " + name + " for ticking");
	}

	export function setTicking(start: boolean) {
		ticking = start;
	}
}

RunService.Heartbeat.Connect((deltaTime) => {
	// end is highest priority (runs first), beginning is lowest priority (runs last)
	if (ticking) {
		for (let i = TickManager.ToTickEntries.size() - 1; i >= 0; i--) {
			TickManager.ToTickEntries[i][1](deltaTime);
		}
	}
});

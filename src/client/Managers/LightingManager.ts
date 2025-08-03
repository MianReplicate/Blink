import { Lighting } from "@rbxts/services";

export type LightingType = "Lobby" | "Round";

const lobbyRecord = {
	Brightness: 1.2,
} as const;

const roundRecord = {
	Brightness: 0,
} as const;

export namespace LightingManager {
	export function setLightingType(lightingType: LightingType) {
		const record = lightingType === "Lobby" ? lobbyRecord : roundRecord;

		for (const [key, value] of pairs(record)) {
			Lighting[key] = value;
		}
	}
}

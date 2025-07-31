import { Players, ReplicatedStorage, RunService } from "@rbxts/services";

const Settings = ReplicatedStorage.WaitForChild("Settings");
const GroupId = 10874599;

export namespace Util {
	export function isAdmin(player: Player) {
		return RunService.IsStudio() || player.GetRankInGroup(GroupId) >= 254 || Settings.GetAttribute("Testing");
	}

	export function isTester(player: Player) {
		return RunService.IsStudio() || player.GetRankInGroup(GroupId) >= 253 || Settings.GetAttribute("Testing");
	}

	export function getPlayerFromName(name: string, displayName?: boolean) {
		if (!name) return;
		name = name.lower();
		Players.GetPlayers().forEach((player) => {
			if (
				(displayName !== false && player.DisplayName.lower().match(name)[0]) ||
				(displayName !== true && player.Name.lower().match(name)[0])
			)
				return player;
		});
	}
}

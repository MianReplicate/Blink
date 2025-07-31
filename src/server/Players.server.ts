import { Players, ReplicatedStorage } from "@rbxts/services";
import { Util } from "shared/Util";
import { GameHelper } from "./GameLibrary";

type Command = (player: Player, args: string[]) => unknown;

const Settings = ReplicatedStorage.WaitForChild("Settings");
const prefix = "/";
const commands = new Map<string, Command>();

commands.set("becomerole", (player, args) => {
	const role = args[0];
	const optionalPlayerName = args[1];
	player = (optionalPlayerName && Util.getPlayerFromName(optionalPlayerName)) || player;

	// GameLibrary.becomeRole(player);
});

function handleCommand(player: Player, message: string) {
	if (!Util.isAdmin(player)) return;

	const indexStart = message.find(prefix)[0];
	if (indexStart === 1) {
		message = message.sub(2);
		const split = message.split(" ");
		const command = split[1].lower();
		split.remove(0);

		const commandFunc = commands.get(command);
		if (commandFunc !== undefined) {
			commandFunc(player, split);
		} else {
			warn(`{command} is not a valid command! | Used by {player}`);
		}
	}
}

Players.PlayerAdded.Connect((player) => {
	if (Settings.GetAttribute("Testing")) {
		if (!Util.isTester(player)) player.Kick("Must be a tester to join!");
	}

	player.Chatted.Connect((message) => handleCommand(player, message));
});

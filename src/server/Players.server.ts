import { Players, ReplicatedStorage } from "@rbxts/services";
import { Util } from "shared/Util";
import { ActorManager } from "./Managers/ActorManager";
import { TickManager } from "shared/Managers/TickManager";
import { ActorType } from "shared/Types";

type Command = (player: Player, args: string[]) => unknown;

const Settings = ReplicatedStorage.WaitForChild("Settings");
const prefix = "/";
const commands = new Map<string, Command>();

commands.set("becomerole", (player, args) => {
	const role = args[0].lower();
	const optionalPlayerName = args[1];
	player = (optionalPlayerName && Util.getPlayerFromName(optionalPlayerName)) || player;

	ActorManager.changeIntoRole("survivor".match(role)[0] ? ActorType.Survivor : ActorType.Survivor, player);
});

commands.set("tick", (player, args) => {
	const start = args[0].lower();
	if (start === "true") {
		TickManager.setTicking(true);
	} else if (start === "false") {
		TickManager.setTicking(false);
	}
});

function handleCommand(player: Player, message: string) {
	if (!Util.isAdmin(player)) return;

	const indexStart = message.find(prefix)[0];
	if (indexStart === 1) {
		message = message.sub(2);
		const split = message.split(" ");
		const command = split[0].lower();
		split.remove(0);

		const commandFunc = commands.get(command);
		if (commandFunc !== undefined) {
			try {
				commandFunc(player, split);
			} catch (error) {
				print("An error occurred when running the", command, "command!", error);
			}
		} else {
			warn(command + ` is not a valid command! | Used by ` + player.Name);
		}
	}
}

Players.PlayerAdded.Connect((player) => {
	if (Settings.GetAttribute("Testing")) {
		if (!Util.isTester(player)) player.Kick("Must be a tester to join!");
	}

	player.Chatted.Connect((message) => handleCommand(player, message));
	player.CharacterAdded.Connect((character) =>
		character
			.GetDescendants()
			.filter((value) => value.IsA("BasePart"))
			.forEach((value) => (value.CollisionGroup = "Characters")),
	);
});

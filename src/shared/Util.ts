import { Math } from "@rbxts/luau-polyfill";
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

	export function getWalkDirection(humanoid: Humanoid) {
		let moveDirection;
		const walkToPoint = humanoid.WalkToPoint;
		const walkToPart = humanoid.WalkToPart;
		if (humanoid.MoveDirection !== Vector3.zero) {
			moveDirection = humanoid.MoveDirection;
		} else if (walkToPart || walkToPoint !== Vector3.zero) {
			const destination = walkToPart ? walkToPart.CFrame.PointToWorldSpace(walkToPoint) : walkToPoint;
			let moveVector = Vector3.zero;
			if (humanoid.RootPart) {
				moveVector = destination.sub(humanoid.RootPart.CFrame.Position);
				moveVector = new Vector3(moveVector.X, 0.0, moveVector.Z);
				const mag = moveVector.Magnitude;
				if (mag > 0.01) {
					moveVector = moveVector.div(mag);
				}
			}
			moveDirection = moveVector;
		} else {
			moveDirection = humanoid.MoveDirection;
		}

		assert(humanoid.RootPart);

		const cframe = humanoid.RootPart.CFrame;
		const lookat = cframe.LookVector;
		let direction = new Vector3(lookat.X, 0.0, lookat.Z);
		direction = direction.div(direction.Magnitude);
		let ly = moveDirection.Dot(direction);
		if (ly <= 0.0 && ly > -0.05) {
			ly = 0.0001;
		}
		const lx = direction.X * moveDirection.Z - direction.Z * moveDirection.X;
		const tempDir = new Vector2(lx, ly);
		return tempDir;
	}
}

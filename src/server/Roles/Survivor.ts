import { ReplicatedStorage, TweenService } from "@rbxts/services";
import { PlayerKeyPredicate, ServerDataObject } from "../ServerDataManager";
import { Actor } from "./Actor";

export class Survivor extends Actor {
	constructor(character: Instance, player?: Player) {
		super(ServerDataObject.getOrConstruct<Instance>(character, ["Survivor"]));

		const humanoid = character.WaitForChild("Humanoid") as Humanoid;
		let animator = humanoid.FindFirstChild("Animator") as Animator;
		if (animator === undefined) {
			animator = new Instance("Animator");
			animator.Parent = humanoid;
		}

		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff;
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
		humanoid.UseJumpPower = true;
		humanoid.JumpPower = 0;
		humanoid.BreakJointsOnDeath = false;

		this.data.setValue("blinking", false);
		this.data.setValue("blinkTrack", animator.LoadAnimation(ReplicatedStorage.SurvivorAnimations.Blink.Clone()));

		if (player !== undefined) {
			this.data.setValue("player", player);

			const predicate: PlayerKeyPredicate = (_player: Player) => {
				return { canSeeKey: _player.UserId === player.UserId, canSeeValue: true, canEditValue: false };
			};

			this.data.setPlayerCriteriaForKeys(["blinking", "blinkMeter", "dead", "maxBlinkMeter"], predicate);
			this.data.setCriteriaForDataObject((_player) => _player.UserId === player.UserId);
		}

		character.Archivable = true;
	}

	public blink() {
		if (!this.isAlive()) return;

		if (this.data.getValue<boolean>("blinking")) return;
	}

	public queueStraining(start: boolean) {
		if (!this.isAlive()) return;

		this.data.setValue("straining", start ? os.clock() : undefined);
	}

	public setBlinkMeter(newValue: number) {
		if (!this.isAlive()) return;

		this.data.setValue("blinkMeter", math.min(newValue, this.data.getValue("maxBlinkMeter")));
		const track = this.data.getValue<AnimationTrack>("blinkTrack");
		const trackTime = math.min(1 - newValue / this.data.getValue<number>("maxBlinkMeter"), 0.99);
		const useTime =
			(newValue === 100 && this.data.getValue<number>("blinkResetTimer") / 2) ||
			this.data.getValue<number>("strainTime");
		const tInfo = new TweenInfo(useTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false, 0);
		const tweenToPosition = TweenService.Create(track, tInfo, { TimePosition: trackTime });
		if (!track.IsPlaying) {
			track.Play();
			track.AdjustSpeed(0);
		}
		tweenToPosition.Play();
	}

	public isAlive() {
		return !this.data.getValue<boolean>("dead");
	}

	public die() {}
}

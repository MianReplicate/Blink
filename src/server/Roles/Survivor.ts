import { ReplicatedStorage, TweenService } from "@rbxts/services";
import { PlayerKeyPredicate, ServerDataObject } from "../ServerDataManager";
import { Actor } from "./Actor";

export const SurvivorList = ServerDataObject.getOrConstruct<string>("List", ["Survivor"]);

SurvivorList.setCriteriaForDataObject((plr) => true);
SurvivorList.setFutureCriteriaForKeys((plr) => {
	return { canSeeKey: true, canSeeValue: false, canEditValue: false };
});

export class Survivor extends Actor {
	public static getOrCreate(character: Model, player?: Player): Survivor {
		let survivor = SurvivorList.getValue<Survivor>(character);
		if (survivor !== undefined) return survivor;

		survivor = new Survivor(character);
		SurvivorList.setValue(character, survivor);

		return survivor;
	}

	private constructor(character: Instance, player?: Player) {
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

		this.defaultValues();
	}

	public defaultValues() {
		this.data.setValue("maxBlinkMeter", 100);
		this.data.setValue("blinkMeter", this.data.getValue("maxBlinkMeter"));
		this.data.setValue("blinkResetTimer", 0.3);

		this.data.setValue("drainAmount", 10);

		this.data.setValue("straining", undefined);
		this.data.setValue("strainTime", 1);
		this.data.setValue("minStrainTime", 0.2);

		this.data.setValue("strainIncrease", 15);
		this.data.setValue("minStrainIncrease", 0);
	}

	public blink() {
		if (!this.isAlive()) return;

		if (this.data.getValue<boolean>("blinking")) return;

		this.queueStraining(false);
		this.data.setValue("strainTime", this.data.getValue<number>("blinkResetTimer") / 2);
		this.setBlinkMeter(0);
		this.defaultValues();
		this.data.setValue("blinking", os.clock());
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

	public strain() {
		if (!this.isAlive()) return;

		const blinkMeter = this.data.getValue<number>("blinkMeter");
		const strainIncrease = this.data.getValue<number>("strainIncrease");
		if (
			blinkMeter < this.data.getValue<number>("maxBlinkMeter") &&
			strainIncrease > 0 &&
			!this.data.getValue<boolean>("blinking")
		) {
			this.setBlinkMeter(blinkMeter + strainIncrease);
			this.data.setValue(
				"strainIncrease",
				math.max(strainIncrease - 0.6, this.data.getValue<number>("minStrainIncrease")),
			);
			this.data.setValue(
				"strainTime",
				math.max(this.data.getValue<number>("strainTime") - 0.04, this.data.getValue<number>("minStrainTime")),
			);
		}
	}

	public isAlive() {
		return !this.data.getValue<boolean>("dead");
	}

	public die() {}

	public destroy() {
		SurvivorList.removeKey(this.getData().getHolder());
		this.getData().destroy();
	}

	public tick() {
		super.tick();

		const strainValue = this.data.getValue<number>("straining");
		if (strainValue !== undefined) {
			const deltaTime = os.clock() - strainValue;
			if (deltaTime > this.data.getValue<number>("strainTime")) {
				const newBlinkMeter = math.max(
					this.data.getValue<number>("blinkMeter") - this.data.getValue<number>("drainAmount"),
					0,
				);
				this.setBlinkMeter(newBlinkMeter);

				if (this.data.getValue<number>("blinkMeter") <= 0) {
					this.data.setValue("straining", undefined);
					this.blink();
				} else {
					this.data.setValue("straining", os.clock());
				}
			}
		} else {
			// currently blinking
			const deltaTime = os.clock() - this.data.getValue<number>("blinking");
			if (deltaTime >= this.data.getValue<number>("blinkResetTimer")) {
				this.data.setValue("blinking", undefined);
				this.setBlinkMeter(this.data.getValue("blinkMeter"));
				this.queueStraining(true);
			}
		}
	}
}

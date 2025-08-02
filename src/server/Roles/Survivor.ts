import {
	PhysicsService,
	Players,
	ReplicatedStorage,
	ServerScriptService,
	TweenService,
	Workspace,
} from "@rbxts/services";
import { PlayerKeyPredicate, ServerDataObject } from "../ServerDataObject";
import { Actor } from "./Actor";
import { Array } from "@rbxts/luau-polyfill";
import { Util } from "shared/Util";
import EasyRagdoll from "shared/EasyRagdoll";

export const SurvivorList = ServerDataObject.getOrConstruct<string>("List", ["Survivor"]);

SurvivorList.setCriteriaForDataObject(() => true);
SurvivorList.setFutureCriteriaForKeys(() => {
	return { canSeeKey: true, canSeeValue: false, canEditValue: false };
});

export class Survivor extends Actor {
	public static getOrCreate(character: Model, player?: Player): Survivor {
		let survivor = SurvivorList.getValue<Survivor>(character);
		if (survivor !== undefined) return survivor;

		survivor = new Survivor(character, player);
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

		this.data.setValue("blinking", undefined);
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
		this.queueStraining(true);
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

	public blink(): boolean {
		if (!this.isAlive()) return false;

		if (this.data.getValue<number>("blinking") !== undefined) return false;

		this.defaultValues();
		this.setBlinkMeter(0, true);
		this.data.setValue("blinking", os.clock());

		return true;
	}

	public queueStraining(start: boolean) {
		if (!this.isAlive()) return;

		this.data.setValue("straining", start ? os.clock() : undefined);
	}

	public setBlinkMeter(newValue: number, fastAnimation?: boolean) {
		if (!this.isAlive()) return;

		this.data.setValue("blinkMeter", math.min(newValue, this.data.getValue("maxBlinkMeter")));
		const track = this.data.getValue<AnimationTrack>("blinkTrack");
		const trackTime = math.min(1 - newValue / this.data.getValue<number>("maxBlinkMeter"), 0.99);
		const useTime = fastAnimation
			? this.data.getValue<number>("blinkResetTimer") / 2
			: this.data.getValue<number>("strainTime");
		const tInfo = new TweenInfo(useTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false, 0);
		const tweenToPosition = TweenService.Create(track, tInfo, { TimePosition: trackTime });
		if (!track.IsPlaying) {
			track.Play();
			track.AdjustSpeed(0);
		}
		tweenToPosition.Play();
	}

	public strain(): boolean {
		if (!this.isAlive()) return false;

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
			return true;
		}
		return false;
	}

	public isAlive() {
		return !this.data.getValue<boolean>("dead");
	}

	public die() {
		super.die();
		const character = this.getData().getHolder();
		if (character !== undefined) {
			const clone = character.Clone() as Model;
			clone
				.GetDescendants()
				.filter((value) => value.IsA("BaseScript"))
				.forEach((value) => value.Destroy());
			clone.Parent = Workspace;
			clone.Name = "Ragdoll";

			character.Destroy();

			EasyRagdoll.SetRagdoll(clone, true, false);
			// clone
			// 	.GetChildren()
			// 	.filter(
			// 		(value) =>
			// 			value.Name !== "HumanoidRootPart" && value.Name !== "CollisionPart" && value.IsA("BasePart"),
			// 	)
			// 	.forEach((value) => {
			// 		if (value.IsA("BasePart")) {
			// 			value.CanCollide = true;
			// 			value.GetPropertyChangedSignal("CanCollide").Connect(() => (value.CanCollide = true));
			// 		}
			// 	});
			// (clone.WaitForChild("CollisionPart") as BasePart).CanCollide = false;
			// (clone.WaitForChild("HumanoidRootPart") as BasePart).CanCollide = false;
			clone
				.GetDescendants()
				.filter((value) => value.IsA("BasePart"))
				.forEach((value) => (value.CollisionGroup = "Ragdolls"));

			const player = this.data.getValue<Player>("player");
			if (player !== undefined) {
				task.spawn(() => {
					task.wait(Players.RespawnTime);
					player.LoadCharacter();
				});
			}
		}
		this.destroy();
	}

	public destroy() {
		SurvivorList.removeKey(this.getData().getHolder());
		super.destroy();
	}

	public tick() {
		super.tick();

		if (!this.isAlive()) return;

		const humanoid = this.data.getHolder().FindFirstChildWhichIsA("Humanoid");
		if (humanoid !== undefined) {
			humanoid.WalkSpeed = Util.getWalkDirection(humanoid).Y >= 0 ? 16 : 10;
		}

		const strainValue = this.data.getValue<number>("straining");
		const blinking = this.data.getValue<number>("blinking");
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
		} else if (blinking !== undefined) {
			// currently blinking
			const deltaTime = os.clock() - blinking;
			if (deltaTime >= this.data.getValue<number>("blinkResetTimer")) {
				this.data.setValue("blinking", undefined);
				this.setBlinkMeter(this.data.getValue("maxBlinkMeter"), true);
				this.queueStraining(true);
			}
		}
	}
}

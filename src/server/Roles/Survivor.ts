import { TweenService } from "@rbxts/services";
import { ServerDataObject } from "../ServerDataManager";
import { Actor } from "./Actor";

export class Survivor extends Actor {
	constructor(character: Instance) {
		super(ServerDataObject.getOrConstruct<Instance>(character, ["Survivor"]));
		// this.data.setValue("classHolder", this);
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

import { Lighting, Players, ReplicatedStorage, TweenService, UserInputService } from "@rbxts/services";
import { ClientDataObject } from "./ClientDataObject";
import { MobileManager } from "./Managers/MobileManager";
import { ControlManager } from "./Managers/ControlManager";
import { Object } from "@rbxts/luau-polyfill";
import { ActorType } from "shared/Types";

type LightingType = "Lobby" | "Round";

const ClientUI = ReplicatedStorage.Client;
const SurvivorVision = Lighting.SurvivorVision;
const SurvivorBlur = Lighting.SurvivorBlur;
const Player: Player = Players.LocalPlayer;
let activeRoundUI: typeof ReplicatedStorage.Client.RoundUI | undefined = undefined;

const lobbyRecord = {
	Brightness: 1.2,
} as const;

const roundRecord = {
	Brightness: 0,
} as const;

function setLightingType(lightingType: LightingType) {
	const record = lightingType === "Lobby" ? lobbyRecord : roundRecord;

	for (const [key, value] of pairs(record)) {
		Lighting[key] = value;
	}
}

ControlManager.bind(Enum.KeyCode.Q, "Blink");
ControlManager.bind(Enum.KeyCode.Space, "Strain");
ControlManager.bind(Enum.KeyCode.ButtonB, "Blink");
ControlManager.bind(Enum.KeyCode.ButtonA, "Strain");

function resetUI() {
	activeRoundUI?.Destroy();
	Player.CameraMode = Enum.CameraMode.Classic;

	SurvivorVision.TintColor = Color3.fromRGB(255, 255, 255);
	SurvivorBlur.Size = 0;
}

function onRoleDelete() {
	resetUI();
	setLightingType("Lobby");
}

function onRoleCreate(role: ActorType, roleData: ClientDataObject<Instance>) {
	resetUI();

	activeRoundUI = ClientUI.RoundUI.Clone();
	activeRoundUI.Common.Visible = true;

	Player.CameraMode = Enum.CameraMode.LockFirstPerson;

	setLightingType("Round");

	if (role === "Survivor") {
		activeRoundUI.Survivor.Visible = true;

		const MainFrame = activeRoundUI.Survivor;
		const BlinkFrame = MainFrame.Blink;
		const MobileList = MainFrame.MobileList;
		const Half1 = BlinkFrame.Half1;
		const Half2 = BlinkFrame.Half2;
		const MaxDifference = 0.2;
		const MaxValue = roleData.waitForValue<number>("maxBlinkMeter") as number;

		roleData.addListener<number>({
			key: "blinking",
			callback: (_, NewValue, OldValue) => {
				let half1Tween;
				let half2Tween;
				let tweenBlinkFrame;

				if (NewValue !== undefined) {
					const Scale = Half2.Position.Y.Scale;
					const AmountInChange = (MaxDifference - (1 - Scale)) / MaxDifference;
					const _TweenInfo = new TweenInfo(
						math.max(0.3 * AmountInChange, 0.2),
						Enum.EasingStyle.Sine,
						Enum.EasingDirection.Out,
						0,
						false,
					);

					half1Tween = TweenService.Create(Half1, _TweenInfo, {
						Position: UDim2.fromScale(Half1.Position.X.Scale, -0.32),
					});
					half2Tween = TweenService.Create(Half2, _TweenInfo, {
						Position: UDim2.fromScale(Half2.Position.X.Scale, 0.32),
					});
					tweenBlinkFrame = TweenService.Create(BlinkFrame, _TweenInfo, { BackgroundTransparency: 0 });
				} else {
					const _TweenInfo = new TweenInfo(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false);

					half1Tween = TweenService.Create(Half1, _TweenInfo, {
						Position: UDim2.fromScale(Half1.Position.X.Scale, -1),
					});
					half2Tween = TweenService.Create(Half2, _TweenInfo, {
						Position: UDim2.fromScale(Half2.Position.X.Scale, 1),
					});
					tweenBlinkFrame = TweenService.Create(BlinkFrame, _TweenInfo, { BackgroundTransparency: 1 });
				}

				half1Tween.Play();
				half2Tween.Play();
				tweenBlinkFrame.Play();
				tweenBlinkFrame.Completed.Once((_) => {
					SurvivorVision.TintColor = Color3.fromRGB(255, 255, 255);
					SurvivorBlur.Size = 0;
				});
			},
		});

		roleData.addListener<number>({
			key: "blinkMeter",
			callback: (_, NewValue, OldValue) => {
				if (NewValue > 0 && NewValue < MaxValue) {
					const _TweenInfo = new TweenInfo(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false);

					const Difference = MaxDifference * ((MaxValue - NewValue) / MaxValue);
					const Half1Dif = -(1 - Difference);
					const Half2Dif = 1 - Difference;
					const Half1Tween = TweenService.Create(Half1, _TweenInfo, {
						Position: UDim2.fromScale(Half1.Position.X.Scale, Half1Dif),
					});
					const Half2Tween = TweenService.Create(Half2, _TweenInfo, {
						Position: UDim2.fromScale(Half2.Position.X.Scale, Half2Dif),
					});

					Half1Tween.Play();
					Half2Tween.Play();

					SurvivorVision.TintColor = Color3.fromRGB(
						255,
						SurvivorVision.TintColor.G * 255 - 1,
						SurvivorVision.TintColor.G * 255 - 1,
					);
					SurvivorBlur.Size = SurvivorBlur.Size + 0.1;
				}
			},
		});

		MobileManager.add(MobileList);
		ControlManager.bind(MobileList.ManualBlink, "Blink");
		ControlManager.bind(MobileList.Spam, "Strain");
	}

	activeRoundUI.Parent = Player.FindFirstChildOfClass("PlayerGui");
}

const actorTypes = Object.values(ActorType);

actorTypes.forEach((actorType) => {
	const list = ClientDataObject.waitFor<string>("List", ["Survivor"]);
	list?.addListener({
		callback: (key, value, oldValue) => {
			const character = Player.Character;
			if (character !== undefined && key === character.GetAttribute("uuid")) {
				if (value === undefined) {
					onRoleDelete();
				} else {
					onRoleCreate(
						actorType,
						ClientDataObject.waitFor<Instance>(character, [actorType]) as ClientDataObject<Instance>,
					);
				}
			}
		},
	});
});

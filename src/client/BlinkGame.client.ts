import { Lighting, Players, ReplicatedStorage, TweenService, UserInputService } from "@rbxts/services";
import { ClientDataObject } from "./ClientDataObject";
import { MobileManager } from "./Managers/MobileManager";
import { ControlManager } from "./Managers/ControlManager";
import { Object } from "@rbxts/luau-polyfill";
import { ActorType, RoleRemoval } from "shared/Types";
import { LightingManager } from "./Managers/LightingManager";
import { Util } from "shared/Util";

const Client = ReplicatedStorage.Client;
const SurvivorVision = Lighting.SurvivorVision;
const SurvivorBlur = Lighting.SurvivorBlur;
const Player: Player = Players.LocalPlayer;
let activeRoundUI: typeof ReplicatedStorage.Client.RoundUI | undefined = undefined;

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
	LightingManager.setLightingType("Lobby");
	actorTypes.forEach((actorType) => {
		const cleanUp = handleTypes.get(actorType)?.[1];
		if (cleanUp !== undefined) {
			const list = ClientDataObject.waitFor<string>("List", [actorType]);
			list?.getStorage().forEach((value, key) => {
				const character = Util.getInstanceFromUUID(key as string) as Model;
				cleanUp(character);
			});
		}
	});
}

function onRoleCreate(role: ActorType, roleData: ClientDataObject<Instance>) {
	resetUI();

	activeRoundUI = Client.RoundUI.Clone();
	activeRoundUI.Common.Visible = true;

	Player.CameraMode = Enum.CameraMode.LockFirstPerson;

	LightingManager.setLightingType("Round");

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

		roleData.addListener<boolean>({
			key: "dead",
			callback: (key, value, oldValue) => {
				if (value) {
					MainFrame.BackgroundTransparency = 0;
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

// first function is for setting up, second function is for clean up (remove highlights?) if the player dies
const handleTypes: Map<ActorType, [(character: Model) => undefined, (character: Model) => undefined]> = new Map();

handleTypes.set(ActorType.Survivor, [
	(character) => {
		(character.WaitForChild("HumanoidRootPart").WaitForChild("Died") as Sound).Destroy();
	},
	(character) => {},
]);

actorTypes.forEach((actorType) => {
	const list = ClientDataObject.waitFor<string>("List", [actorType]);
	list?.addListener<string>({
		callback: (key, value, oldValue) => {
			const character = Util.getInstanceFromUUID(key as string) as Model;

			if (character !== undefined) {
				if (value !== undefined) {
					handleTypes.get(actorType)?.[0](character);
				}

				if (character === Player.Character) {
					if (value !== undefined) {
						onRoleCreate(
							actorType,
							ClientDataObject.waitFor<Instance>(character, [actorType]) as ClientDataObject<Instance>,
						);
					}
				}
			}
		},
	});
});

RoleRemoval.OnClientEvent.Connect(onRoleDelete);

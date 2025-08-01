import { Lighting, Players, ReplicatedStorage, TweenService, UserInputService } from "@rbxts/services";
import { ActionManager } from "./ActionManager";
import { ActionType } from "shared/RoleActions";
import { ClientDataObject } from "./ClientDataObject";

type Roles = "Survivor" | "Angel";

const ClientUI = ReplicatedStorage.Client;
const SurvivorVision = Lighting.SurvivorVision;
const SurvivorBlur = Lighting.SurvivorBlur;
const Player: Player = Players.LocalPlayer;
let activeRoundUI: typeof ReplicatedStorage.Client.RoundUI | undefined = undefined;

// type EditableLightTypes = "Brightness";
// type LightingProperties = Map<EditableLightTypes, unknown>;
// type LightingType = "Lobby" | "Round";

// const LightingTypes: Map<LightingType, LightingProperties> = new Map();

// const LobbyMap: LightingProperties = new Map();
// LobbyMap.set("Brightness", 1.2);

// const RoundMap: LightingProperties = new Map();
// RoundMap.set("Brightness", 0);

// LightingTypes.set("Lobby", LobbyMap);
// LightingTypes.set("Round", RoundMap);

const ActionMap = new Map<Enum.KeyCode, ActionType>();
ActionMap.set(Enum.KeyCode.Q, "Blink");
ActionMap.set(Enum.KeyCode.Space, "Strain");
ActionMap.set(Enum.KeyCode.ButtonB, "Blink");
ActionMap.set(Enum.KeyCode.ButtonA, "Strain");

// function setLightingType(lightingType: LightingType) {
// 	LightingTypes.get(lightingType)?.forEach((value, key) => {
// 		Lighting[key] = value;
// 	});
// }

function resetUI() {
	activeRoundUI?.Destroy();
	Player.CameraMode = Enum.CameraMode.Classic;

	SurvivorVision.TintColor = Color3.fromRGB(255, 255, 255);
	SurvivorBlur.Size = 0;
}

function onRoleCreate(role: Roles, roleData: ClientDataObject<Instance>) {
	resetUI();

	activeRoundUI = ClientUI.RoundUI.Clone();
	activeRoundUI.Common.Visible = true;

	Player.CameraMode = Enum.CameraMode.LockFirstPerson;

	if (role === "Survivor") {
		activeRoundUI.Survivor.Visible = true;

		const MainFrame = activeRoundUI.Survivor;
		const BlinkFrame = MainFrame.Blink;
		const MobileList = MainFrame.MobileList;
		const Half1 = BlinkFrame.Half1;
		const Half2 = BlinkFrame.Half2;
		const MaxDifference = 0.2;

		roleData.addListener<number>({
			key: "blinking",
			callback: (_, NewValue, OldValue) => {
				let half1Tween;
				let half2Tween;
				let tweenBlinkFrame;

				print(NewValue);
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
				const MaxValue = roleData.getValue<number>("maxBlinkMeter");
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
	}

	activeRoundUI.Parent = Player.FindFirstChildOfClass("PlayerGui");
}

const SurvivorList = ClientDataObject.waitFor<string>("List", ["Survivor"]);
// const AngelList = ClientDataObject.waitFor<string>("List", ["Angel"]);

SurvivorList?.addListener({
	callback: (key, value, oldValue) => {
		const character = Player.Character;
		if (character !== undefined && key === character.GetAttribute("uuid"))
			onRoleCreate(
				"Survivor",
				ClientDataObject.waitFor<Instance>(character, ["Survivor"]) as ClientDataObject<Instance>,
			);
	},
});

UserInputService.InputBegan.Connect((input, gpe) => {
	if (!gpe) {
		const actionType = ActionMap.get(input.KeyCode);
		if (actionType !== undefined) {
			ActionManager.callAction(actionType);
		}
	}
});

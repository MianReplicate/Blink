Players = game:GetService("Players")
TweenService = game:GetService("TweenService")
player = Players.LocalPlayer
Camera = workspace.CurrentCamera
local blurEffect = Instance.new("BlurEffect",Camera)
local colorCorrection = Instance.new("ColorCorrectionEffect",Camera)
colorCorrection.Enabled = false
blurEffect.Size = 0; blurEffect.Enabled = false
local sounds = game.SoundService.SoundGroup	
local effect1 = sounds.ReverbSoundEffect
local effect2 = sounds.EqualizerSoundEffect
local effect3 = sounds.PitchShiftSoundEffect


EFFECT_TIME = Players.RespawnTime - 7.75
BLUR_SIZE = 50
CORRECTION_COLOR = Color3.fromRGB(138, 0, 0)

local BlurEffectInfo = TweenInfo.new(
	EFFECT_TIME,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.Out,
	0,
	false,
	0)

BlurTween = TweenService:Create(blurEffect, BlurEffectInfo, {Size = BLUR_SIZE})


local CorrectionEffectInfo = TweenInfo.new(
	5,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.Out,
	0,
	false,
	0)

ColorTween = TweenService:Create(colorCorrection, CorrectionEffectInfo, {TintColor = CORRECTION_COLOR})

local BrightnessEffectInfo = TweenInfo.new(
	EFFECT_TIME,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.Out,
	0,
	false,
	0)

BrightnessTween = TweenService:Create(colorCorrection, BrightnessEffectInfo, {Brightness = -1})

function setupDeathTweens(character)
	local humanoid = character:WaitForChild("Humanoid")
	blurEffect.Size = 0
	colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
	colorCorrection.Brightness = 0
	if BrightnessTween and BlurTween and ColorTween == Enum.PlaybackState.Playing then
		BrightnessTween:Cancel()
		ColorTween:Cancel()
		BlurTween:Cancel()
	end
	
	colorCorrection.Enabled = false
	blurEffect.Size = 0
	blurEffect.Enabled = false
	
	humanoid.Died:Connect(onDied)
end

function onDied()
	local SoundFade = 0
	blurEffect.Enabled = true
	colorCorrection.Enabled = true
	warn("Died")
	
	ColorTween:Play()
	BrightnessTween:Play()
	BlurTween:Play()
	
	
	effect1.Enabled = true
	effect2.Enabled = true
	effect3.Enabled = true
	
	wait(0.5)
	while SoundFade < 1 do
		wait(0.2)
		sounds.Volume = sounds.Volume - 0.05
		SoundFade = SoundFade + 0.05

	end
	
end

if player.Character then
	setupDeathTweens(player.Character)
end

player.CharacterAdded:Connect(function()
	setupDeathTweens(player.Character)
	print("RESPAWNED")
	
	if sounds.Volume == 0 then
		sounds.Volume = 0.5
	end
	
end)
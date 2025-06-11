local player = game.Players.LocalPlayer
local tool = script.Parent

local animations = tool.Anim

local idleanimtrack = player.Character:FindFirstChild("Humanoid").Animator:LoadAnimation(animations.TWDetectorIdle)

tool.Equipped:Connect(function()
	idleanimtrack:Play()
end)

tool.Unequipped:Connect(function()
	idleanimtrack:Stop()
end)
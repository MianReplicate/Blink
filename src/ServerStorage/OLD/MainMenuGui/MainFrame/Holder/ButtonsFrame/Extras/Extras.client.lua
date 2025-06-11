local optionButton = script.Parent
local player = game:GetService("Players")
local players = player.LocalPlayer
local playerGui = players:WaitForChild("PlayerGui")
local mainMenuGui = playerGui:WaitForChild("MainMenuGui")
local extrasGui = mainMenuGui:WaitForChild("ExtrasFrame")

local function openExtras()
	if not extrasGui.Visible then
		extrasGui.Visible = true
		extrasGui:TweenPosition(UDim2.new(0.5,0,0.5,0), "InOut", "Sine", 0.5)
		mainMenuGui.MainFrame:TweenPosition(UDim2.new(0.5,0,-0.5,0), "InOut", "Sine", 0.5)
		task.wait(0.6)
		mainMenuGui.MainFrame.Visible = false
	end
end

script.Parent.MouseButton1Click:Connect(function()
	openExtras()
end)
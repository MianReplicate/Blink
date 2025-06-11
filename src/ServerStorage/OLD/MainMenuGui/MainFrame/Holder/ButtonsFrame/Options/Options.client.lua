local optionButton = script.Parent
local player = game:GetService("Players")
local players = player.LocalPlayer
local playerGui = players:WaitForChild("PlayerGui")
local mainMenuGui = playerGui:WaitForChild("MainMenuGui")
local optionGui = mainMenuGui:WaitForChild("OptionsFrame")

local function openOptions()
	if not optionGui.Visible then
		optionGui.Visible = true
		optionGui:TweenPosition(UDim2.new(0.5,0,0.5,0), "InOut", "Sine", 0.6)
		mainMenuGui.MainFrame:TweenPosition(UDim2.new(-0.5,0,0.5,0), "InOut", "Sine", 0.6)
		task.wait(0.6)
		mainMenuGui.MainFrame.Visible = false
	end
end

script.Parent.MouseButton1Click:Connect(function()
	openOptions()
end)
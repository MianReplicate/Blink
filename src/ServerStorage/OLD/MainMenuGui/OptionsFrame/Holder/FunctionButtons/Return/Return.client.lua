local optionButton = script.Parent
local player = game:GetService("Players")
local players = player.LocalPlayer
local playerGui = players:WaitForChild("PlayerGui")
local mainMenuGui = playerGui:WaitForChild("MainMenuGui")
local optionsGui = mainMenuGui:WaitForChild("OptionsFrame")

local function closeOptions()
	if optionsGui.Visible then
		mainMenuGui.MainFrame.Visible = true
		optionsGui:TweenPosition(UDim2.new(1.5,0,0.5,0), "InOut", "Sine", 0.6)
		mainMenuGui.MainFrame:TweenPosition(UDim2.new(0.5,0,0.5,0), "InOut", "Sine", 0.6)
		task.wait(0.6)
		optionsGui.Visible = false
	end
end

script.Parent.MouseButton1Click:Connect(function()
	closeOptions()
end)
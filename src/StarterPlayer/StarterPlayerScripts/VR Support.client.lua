local UIS = game:GetService("UserInputService")
local VRService = game:GetService("VRService")
local VREnabled = UIS.VREnabled or VRService.VREnabled

if VREnabled then
	
	print("!VR Enabled!")
	
	
	-- Setup Variables
	local Player = game.Players.LocalPlayer
	local PlayerGui = Player.PlayerGui
	local Character = Player.Character
	local Camera = workspace.Camera
	
	local Runservice = game:GetService("RunService")
	local VrCamGUI = script:WaitForChild("VrCamGUI")
	VrCamGUI.Parent = workspace
	
	
	
	Runservice.RenderStepped:Connect(function() -- Update Important stuff every frame
		-- Update GUI box to make sure the round gui is covering the entire screen
		VrCamGUI.CFrame = Camera:GetRenderCFrame():ToWorldSpace(CFrame.new(0, 0, -1.5))	
	end)
	
	
	PlayerGui.ChildAdded:Connect(function()
		local RoundUI = PlayerGui:FindFirstChild("RoundUI")
		
		if RoundUI then
			task.wait(1) -- Temp Solution
			for count, Frame in RoundUI:GetChildren() do
				Frame.Parent = VrCamGUI.CamGui
			end
		end
	end)
	
	
end

--[[
VrCamGUI.CFrame = Head.CFrame:ToWorldSpace(CFrame.new(0, 0, -.25))
WeldConstraint.Part1 = Head
]]

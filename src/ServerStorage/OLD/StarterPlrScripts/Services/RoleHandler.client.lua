local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local RoundUI = Player.PlayerGui:WaitForChild("RoundUI")
local Character

local communicators = shared.Utils.GetCommunicators()
local RemoteFuncs = shared.Utils.retrieveFunctions()

local SurvivorVision : ColorCorrectionEffect = Lighting:WaitForChild("SurvivorVision")
local SurvivorBlur : BlurEffect = Lighting:WaitForChild("SurvivorBlur")

local roleConnections = {}

function addConnection(connection : RBXScriptConnection)
	table.insert(roleConnections, connection)
end

local roleTypes = {
	[shared.Utils.retrieveEnum("SubTypes.Survivor")] = function()
		local maxValue = communicators.GetValueFromData:InvokeServer(shared.Utils.retrieveEnum("DataTypes.Roles"), Character, {"blinkMeter", "maxValue"})

		addConnection(UserInputService.InputBegan:Connect(function(inputObj, gpe)
			if not gpe then
				if inputObj.KeyCode == Enum.KeyCode.Space then
					communicators.CommunicateEvent:FireServer(shared.Utils.retrieveEnum("DataTypes.Roles"), Character, "keepEyesOpen")
				elseif inputObj.KeyCode == Enum.KeyCode.Q then
					communicators.CommunicateEvent:FireServer(shared.Utils.retrieveEnum("DataTypes.Roles"), Character, "blink")
				end
			end
		end))

		addConnection(communicators.CommunicateEvent.OnClientEvent:Connect(function(datainfo, data)
			if datainfo.datatype == shared.Utils.retrieveEnum("DataTypes.Roles") and datainfo.packettype == shared.Utils.retrieveEnum("PacketTypes.ValueChanged") then -- data changes!
				local ancestry = data.ancestry
				local indexChanged = ancestry[#ancestry]
				local newValue = data.newValue
				local maxDifference = 0.65

				local mainFrame = RoundUI.Survivor.Blink
				local half1 : ImageLabel = mainFrame.Half1
				local half2 : ImageLabel = mainFrame.Half2
				local tweenInfo = TweenInfo.new(
					0.2,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out,
					0,
					false
				)
				if ancestry[1] == "blinkMeter" then
					if newValue ~= 0 then
						local difference = (maxDifference) * ((maxValue - newValue) / maxValue)
						local half1Dif, half2Dif = -(1 - difference), 1 - difference
						local half1Tween = TweenService:Create(half1, tweenInfo, {Position = UDim2.fromScale(half1.Position.X.Scale, half1Dif)})
						local half2Tween = TweenService:Create(half2, tweenInfo, {Position = UDim2.fromScale(half2.Position.X.Scale, half2Dif)})

						half1Tween:Play()
						half2Tween:Play()

						SurvivorVision.TintColor = Color3.fromRGB(255, (SurvivorVision.TintColor.G * 255) - 1, (SurvivorVision.TintColor.G * 255) - 1)
						SurvivorBlur.Size = SurvivorBlur.Size + 0.1
					end
				elseif indexChanged == "blinking" then
					local half1Tween, half2Tween, tweenBlinkFrame
					if newValue then
						local scale = half2.Position.Y.Scale
						local amountInChange =  (maxDifference - (1 - scale)) / maxDifference
						tweenInfo = TweenInfo.new(
							math.max(0.3 * amountInChange, 0.2),
							Enum.EasingStyle.Sine,
							Enum.EasingDirection.Out,
							0,
							false
						)

						half1Tween = TweenService:Create(half1, tweenInfo, {Position = UDim2.fromScale(half1.Position.X.Scale, -0.32)})
						half2Tween = TweenService:Create(half2, tweenInfo, {Position = UDim2.fromScale(half2.Position.X.Scale, 0.32)})
						tweenBlinkFrame = TweenService:Create(mainFrame, tweenInfo, {BackgroundTransparency = 0})
					else
						half1Tween = TweenService:Create(half1, tweenInfo, {Position = UDim2.fromScale(half1.Position.X.Scale, -1)})
						half2Tween = TweenService:Create(half2, tweenInfo, {Position = UDim2.fromScale(half2.Position.X.Scale, 1)})
						tweenBlinkFrame = TweenService:Create(mainFrame, tweenInfo, {BackgroundTransparency = 1})
					end

					half1Tween:Play()
					half2Tween:Play()
					tweenBlinkFrame:Play()
					tweenBlinkFrame.Completed:Once(function()
						SurvivorVision.TintColor = Color3.fromRGB(255, 255, 255)
						SurvivorBlur.Size = 0
					end)
				end
			end
		end))
	end,
}

-- Relies on Character to not have respawned yet
function roleKilled(roleType : string)
	RoundUI.Ignored.DeathScreen.Visible = true
	Player.CharacterAdded:Wait()
	RoundUI.Ignored.DeathScreen.Visible = false
end

-- Resets UI and sets up controls for a role type
function setupRole(roleType : string)
	assert(roleTypes[roleType] and Player.Character, `{roleType} is not a valid roletype or player character does not exist!`)
	noRole()
	Character = Player.Character

	workspace.Camera.CameraSubject = Character
	workspace.Camera.CameraType = Enum.CameraType.Custom
	--Player.CameraMode = Enum.CameraMode.LockFirstPerson

	print(roleType)
	script[roleType]:Clone().Parent = RoundUI
	roleTypes[roleType]()

	print("Set up all info from Role")
end

-- Removes UI and resets everything
function noRole()
	Player.CameraMode = Enum.CameraMode.Classic
	SurvivorVision.TintColor = Color3.fromRGB(255, 255, 255)
	SurvivorBlur.Size = 0
	for _, instance : Instance in RoundUI:GetChildren() do
		if roleTypes[instance.Name] then
			if not script:FindFirstChild(instance.Name) then
				local clone = instance:Clone()
				clone.Parent = script
			end
			instance:Destroy()
		end
	end
	for index, connection : RBXScriptConnection in roleConnections do
		connection:Disconnect()
		table.remove(roleConnections, index)
	end
end

-- TODO: make this work for roles that were added before this remote event was setup
-- Runs for all characters that get a role
shared.Utils.onRemoteEvent("OnRoleAdded", function(roleType : string, characterModel : Model)
	print(`New {roleType}:`, characterModel)
	characterModel:WaitForChild("HumanoidRootPart"):WaitForChild("Died"):Destroy()
end)

-- Check for new roles
communicators.CommunicateEvent.OnClientEvent:Connect(function(datainfo)
	if datainfo.packettype == shared.Utils.retrieveEnum("PacketTypes.RoleChanged") then
		setupRole(datainfo.subtype)
	elseif datainfo.packettype == shared.Utils.retrieveEnum("PacketTypes.RoleRemoved") then
		noRole()
	elseif datainfo.packettype == shared.Utils.retrieveEnum("PacketTypes.RoleKilled") then
		roleKilled(datainfo.subtype)
	end
end)

noRole() -- initial run
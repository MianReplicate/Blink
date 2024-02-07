local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Utils = require(Modules:WaitForChild("Utils"))
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local SurvivorVision = Lighting:WaitForChild("SurvivorVision")
local SurvivorBlur = Lighting:WaitForChild("SurvivorBlur")

--local function getKeypointsForBlinkBar(value, maxValue)
--	local keypoints = {}
--	local keypoint1 = ColorSequenceKeypoint.new(((maxValue - value) / maxValue) * 0.5, Color3.fromRGB(0, 0, 0))
--	local keypoint2 = ColorSequenceKeypoint.new(((value / maxValue) * 0.5) + 0.5, Color3.fromRGB(0, 0, 0))

--	table.insert(keypoints, ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)))
--	table.insert(keypoints, ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)))

--	table.insert(keypoints, keypoint1)
--	table.insert(keypoints, keypoint2)
--	table.insert(keypoints, ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)))

--	local orderedKeypoints = {}
--	local lowestKeypoint = keypoints[1]

--	local initialNumber = #keypoints				
--	for i = 1, initialNumber, 1 do
--		for index, keypoint in keypoints do
--			if keypoint.Time < lowestKeypoint.Time then
--				lowestKeypoint = keypoint
--			end
--		end

--		table.remove(keypoints, table.find(keypoints, lowestKeypoint))
--		table.insert(orderedKeypoints, lowestKeypoint)
--		lowestKeypoint = keypoints[1]
--	end
--	return orderedKeypoints
--end

--local function faketweenKeyPoints(keypointsTweenFrom, keypointsTweenTo, UIGradient : UIGradient)
--	local increment = 0.01
--	local amount = -1

--	local difference = keypointsTweenTo[2].Time - keypointsTweenFrom[2].Time
--	if difference > 0 then
--		increment = 0.01
--	else
--		increment = -0.01
--	end

--	for i = keypointsTweenFrom[2].Time, keypointsTweenTo[2].Time, increment do
--		amount+=1
--	end

--	for i = 1, amount, 1 do
--		local keypoints = {}

--		for index, keypointTweenFrom in keypointsTweenFrom do
--			if (index == 2 or index == 4) and keypointTweenFrom.Time ~= 0.5 then
--				local newTime
--				if index == 2 then
--					newTime = keypointTweenFrom.Time + increment
--				else
--					newTime = keypointTweenFrom.Time - increment
--				end
--				table.insert(keypoints, ColorSequenceKeypoint.new(newTime, Color3.fromRGB(0, 0, 0)))
--			else
--				table.insert(keypoints, keypointTweenFrom)
--			end
--		end
--		UIGradient.Color = ColorSequence.new(keypoints)
--		keypointsTweenFrom = UIGradient.Color.Keypoints
--		task.wait(.02)
--	end
--end

Player.CameraMode = Enum.CameraMode.Classic

if CommunicateEvent and GetDataFunction then
	local roleType = CommunicateEvent.OnClientEvent:Wait()
	workspace.Camera.CameraSubject = Player.Character
	workspace.Camera.CameraType = Enum.CameraType.Custom
	
	print(roleType)
	script.Parent[roleType].Visible = true
	--Player.CameraMode = Enum.CameraMode.LockFirstPerson
	if roleType == "Survivor" then
		local clickedSpace = false
		local prevBlinkValue
		local maxStrengthSecond = 25
		local strengthSeconds = 0
		local justBlinked = false
		
		UserInputService.InputBegan:Connect(function(inputObj, gpe)
			if not gpe then
				if inputObj.KeyCode == Enum.KeyCode.Space then
					CommunicateEvent:FireServer("keepEyesOpen")
				elseif inputObj.KeyCode == Enum.KeyCode.Q then
					CommunicateEvent:FireServer("blink")
				end
			end
		end)
		
		CommunicateEvent.OnClientEvent:Connect(function(data)
			if typeof(data) == 'table' then -- data changes!
				local parents = data[1]
				local indexChanged = data[#data-1]
				local newValue = data[#data]
				local maxDifference = 0.65
				
				local mainFrame = script.Parent.Survivor.Blink
				local half1 : ImageLabel = mainFrame.Half1
				local half2 : ImageLabel = mainFrame.Half2
				local tweenInfo = TweenInfo.new(
					0.2,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out,
					0,
					false
				)
				if parents[1] == "blinkMeter" then
					--local UIGradient : UIGradient = script.Parent[roleType].List.Bar.UIGradient

					if newValue ~= 0 then
						local maxValue = GetDataFunction:InvokeServer(parents, "maxValue")

						local difference = (maxDifference) * ((maxValue - newValue) / maxValue)
						local half1Dif, half2Dif = -(1 - difference), 1 - difference
						local half1Tween = TweenService:Create(half1, tweenInfo, {Position = UDim2.fromScale(half1.Position.X.Scale, half1Dif)})
						local half2Tween = TweenService:Create(half2, tweenInfo, {Position = UDim2.fromScale(half2.Position.X.Scale, half2Dif)})

						half1Tween:Play()
						half2Tween:Play()
						
						if prevBlinkValue and prevBlinkValue < newValue and not clickedSpace and not justBlinked then
							clickedSpace = true
							coroutine.wrap(function()
								while not justBlinked do
									task.wait(1)
									if not justBlinked then
										strengthSeconds = math.min(strengthSeconds + 1, maxStrengthSecond)

										local percentageStrength = strengthSeconds/maxStrengthSecond
										local survivorVision = 100 * percentageStrength
										local survivorVisionTween = TweenService:Create(SurvivorVision, tweenInfo, {TintColor = Color3.fromRGB(255, 255 - survivorVision, 255 - survivorVision)})
										survivorVisionTween:Play()

										local survivorBlurTween = TweenService:Create(SurvivorBlur, tweenInfo, {Size = 5 * percentageStrength})
										survivorBlurTween:Play()
									end
								end
								strengthSeconds = 0
								justBlinked = false
							end)()
						end
						
						prevBlinkValue = newValue
					end

					--faketweenKeyPoints(UIGradient.Color.Keypoints, getKeypointsForBlinkBar(newValue, maxValue), UIGradient)
				elseif indexChanged == "blinking" then
					local half1Tween, half2Tween, tweenBlinkFrame
					if newValue then
						if clickedSpace then
							justBlinked = true
						end
						prevBlinkValue = nil
						local survivorVisionTween = TweenService:Create(SurvivorVision, tweenInfo, {TintColor = Color3.fromRGB(255, 255, 255)})
						survivorVisionTween:Play()

						local survivorBlurTween = TweenService:Create(SurvivorBlur, tweenInfo, {Size = 0})
						survivorBlurTween:Play()
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
						clickedSpace = false
						
						half1Tween = TweenService:Create(half1, tweenInfo, {Position = UDim2.fromScale(half1.Position.X.Scale, -1)})
						half2Tween = TweenService:Create(half2, tweenInfo, {Position = UDim2.fromScale(half2.Position.X.Scale, 1)})
						tweenBlinkFrame = TweenService:Create(mainFrame, tweenInfo, {BackgroundTransparency = 1})
					end

					half1Tween:Play()
					half2Tween:Play()
					tweenBlinkFrame:Play()
				end
			end
		end)
	end
	
	print("Set up all info from Role")
end

Utils.onRemoteEvent("OnAngelAdded", function(characterModel : Model)
	print("New Angel:", characterModel)
end)

Utils.onRemoteEvent("OnSurvivorAdded", function(characterModel : Model)
	print("New Survivor:", characterModel)
end)
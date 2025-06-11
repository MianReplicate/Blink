local players = game:GetService("Players")
local player = players.LocalPlayer
local mainMenuGui = script.Parent.Parent.Parent.Parent.Parent
local tweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true)
local starterGui = game:GetService("StarterGui")
local mainMenuMusic = mainMenuGui:FindFirstChild("MainMenu"):GetChildren()
local darkLight = false
local lighting = game:GetService("Lighting")
local cooldownLight = false
local menuFolder = workspace:WaitForChild("MainMenuFolder")
local lightModel = menuFolder:WaitForChild("Lightbulb"):WaitForChild("Model")
local bulb = lightModel:WaitForChild("Bulb"):WaitForChild("PointLight")
local light = lightModel:WaitForChild("Light")
local lightFlicker
local camera = workspace.CurrentCamera

local connection
local connection2

function setCamera()
	local char = player.Character or player.CharacterAdded:Wait()
	local point1 = workspace.MainMenuFolder.Camera1
	local mouse = player:GetMouse()
	local maxTilt = 10

	connection2 = camera:GetPropertyChangedSignal("CameraType"):Connect(function()
		if camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Scriptable
		end
	end)

	repeat
		camera.CameraType = Enum.CameraType.Scriptable
	until camera.CameraType == Enum.CameraType.Scriptable
	camera.CFrame = point1.CFrame
	starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

	mainMenuMusic[math.random(1, #mainMenuMusic)]:Play()

	connection = game:GetService("RunService").Heartbeat:Connect(function()
		camera.CFrame = point1.CFrame * CFrame.Angles(
			math.rad((((mouse.Y - mouse.ViewSizeY / 2) / mouse.ViewSizeY)) * -maxTilt),
			math.rad((((mouse.X - mouse.ViewSizeX / 2) / mouse.ViewSizeX)) * -maxTilt),
			0
		)
	end)
end

function playGame()
	local char = player.Character or player.CharacterAdded:Wait()
	if not mainMenuGui.FadeFrame.Visible then
		mainMenuGui.FadeFrame.Visible = true
		local tween = tweenService:Create(mainMenuGui.FadeFrame, tweenInfo, {BackgroundTransparency = 0})

		tween:Play()
		task.wait(1.5)
		mainMenuGui.MainFrame.Visible = false
		if connection then
			connection:Disconnect()
		end
		if connection2 then
			connection2:Disconnect()
		end

		camera.CameraSubject = char
		camera.CameraType = Enum.CameraType.Custom
		starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)

		for _, instance in mainMenuMusic do
			instance:Stop()
		end

		coroutine.close(lightFlicker)
		task.wait(1.5)
		mainMenuGui.Enabled = false
	end
end

mainMenuGui.Enabled = true
lighting.Brightness = 0
lighting.ClockTime = 0
setCamera()

local randomAngelChance = math.random(1, 125)
if randomAngelChance <= 1 then
	menuFolder.MainMenuAngelCommon:Destroy()
else
	menuFolder.MainMenuAngelRare:Destroy()
end

lightFlicker = coroutine.create(function()
	while task.wait() do
		local number = math.random(1, 100)

		if number <= 1 then
			if not darkLight then
				local newRandom = Random.new()
				local randomIncrement = newRandom:NextNumber(-0.08, -0.5)

				for i = bulb.Brightness, 0 + randomIncrement, randomIncrement do
					task.wait()
					bulb.Brightness = i
					light.Transparency = 1 - i

					if i > 1 then
						i = 1
					elseif i < 0 then
						i = 0
					end

					if bulb.Brightness <= 0.1 then
						darkLight = true
					end
				end

				task.wait(newRandom:NextNumber(0.1, 0.5))
				number = math.random(1, 5)
				if number <= 1 then
					cooldownLight = true
				end
			end
		else
			if darkLight and not cooldownLight then
				local newRandom = Random.new()
				local randomIncrement = newRandom:NextNumber(0.08, 0.5)

				for i = 0, 1 + randomIncrement, randomIncrement do
					task.wait()
					bulb.Brightness = i
					light.Transparency = 1 - i

					if i > 1 then
						i = 1
					elseif i < 0 then
						i = 0
					end

					if bulb.Brightness > 0.1 then
						darkLight = false
					end
				end
			elseif cooldownLight then
				local newRandom = Random.new()

				cooldownLight = false
				task.wait(newRandom:NextNumber(0.1, 0.5))
			end
		end
	end
end)

coroutine.resume(lightFlicker)

script.Parent.MouseButton1Click:Connect(function()
	playGame()
end)
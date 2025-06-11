local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ClientDataCreator = require(script.Parent:WaitForChild("ClientDataCreator"))
local RoleCommunication = require(Modules:WaitForChild("RoleCommunication"))
local AngelAnimations = ReplicatedStorage:WaitForChild("AngelAnimations")
local Sounds = ReplicatedStorage:WaitForChild("Sounds")
local Settings = script:WaitForChild("Settings")

local Angels
local Survivors
local Lights
local visionExcludables

local Util = require(Modules:WaitForChild("Util"))
local Player = Players.LocalPlayer

local SurvivorVision : ColorCorrectionEffect = Lighting:WaitForChild("SurvivorVision")
local SurvivorBlur : BlurEffect = Lighting:WaitForChild("SurvivorBlur")

local roundUI : ScreenGui = nil
local currentRole = nil
local assigning = false

local heatsenseActive = false

local lighting = {
	lobby = {
		Brightness = 1.2
	},
	round = {
		Brightness = 0
	}
}

local gpeWhitelist = {
	Enum.KeyCode.ButtonA;
	Enum.KeyCode.F;
}

local function retrieve()
	Angels = ClientDataCreator.get("List", "Angels", 5)
	Survivors = ClientDataCreator.get("List", "Survivors", 5)
	Lights = ClientDataCreator.get("List", "Lights", 5)
	visionExcludables = ClientDataCreator.get("List", "VisionExcludables", 5)
	
	if(not Angels or not Survivors or not Lights or not visionExcludables) then
		warn("Some essential data isn't able to be retrieved. We're going to attempt it again but if this keeps happening, please report it if your AVG ping is not above 100.")
		retrieve()
	end
end

retrieve()

local function adjustLighting(setting : string)
	local settings = lighting[setting]
	for key, value in settings do
		Lighting[key] = value
	end
end

local roleConnections : {RBXScriptConnection} = {}

local function handleCharacterWithRole(character : Model, role : string)
	role = role:lower()
	local hrp = character:WaitForChild("HumanoidRootPart", 3)
	if(hrp) then
		local sounds = nil
		if(role == 'survivor') then
			sounds = {"Died"}
			
			if(currentRole == 'Angel') then
				local highlight = script.Highlights.Survivor:Clone()
				highlight.FillTransparency = 1
				highlight.OutlineTransparency = 1
				highlight.Parent = character
			else
				local highlight = character:FindFirstChildWhichIsA("Highlight")
				if(highlight) then highlight:Destroy() end
			end
		elseif role == 'angel' then
			sounds = {"Died", "Running"}
			
			if(currentRole == 'Angel') then
				script.Highlights.Angel:Clone().Parent = character
			else
				local highlight = character:FindFirstChildWhichIsA("Highlight")
				if(highlight) then highlight:Destroy() end
			end
		end
		
		for _, sound in sounds do
			local soundInstance = hrp:WaitForChild(sound, 1)
			if(soundInstance) then soundInstance:Destroy() end
		end
	end
end

local function handleAllCharacters()
	for key, _ in Survivors:getStorage() do
		key = ClientDataCreator.getInstanceFromUUID(key, true)
		if key ~= nil and typeof(key) == 'instance' then
			task.spawn(handleCharacterWithRole, key, "Survivor")
		end
	end

	for key, _ in Angels:getStorage() do
		key = ClientDataCreator.getInstanceFromUUID(key, true)
		if key ~= nil and typeof(key) == 'instance' then
			task.spawn(handleCharacterWithRole, key, "Angel")
		end
	end
end

local function addRoleConnection(connection : RBXScriptConnection)
	table.insert(roleConnections, connection)
end

local function disconnectRoleConnections()
	for i, connection in roleConnections do
		connection:Disconnect()
	end
	
	roleConnections = {}
end

local function loopTracks(tracks)
	local randomTrack : AnimationTrack = tracks[math.random(1, #tracks)]
	randomTrack.Looped = false
	randomTrack:Play()
	addRoleConnection(
		randomTrack.Ended:Connect(function()
			loopTracks(tracks)
		end)
	)
end

local function died(oldValue, newValue)
	if(newValue) then
		currentRole = nil
		handleAllCharacters()
		disconnectRoleConnections()
		roundUI.Survivor.Visible = false
		roundUI.Angel.Visible = false
		roundUI.Common.DeathScreen.Visible = true
	end
end

local function playNewSoundAndRemove(sound : Sound)
	sound.Parent = script
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	sound:Play()
end


local musicSounds = {}
local startNewSong = true

local function loopAndPlayMusic(sounds : {Instance})
	if(currentRole) then
		local latestSong = musicSounds[#musicSounds]
		if(startNewSong) then
			startNewSong = false
			local randomSong : Sound
			
			repeat
				randomSong = sounds[math.random(1, #sounds)]
			until not latestSong or randomSong.Name ~= latestSong.Name
			
			randomSong = randomSong:Clone()
			table.insert(musicSounds, randomSong)
			playNewSoundAndRemove(randomSong)
		elseif(latestSong) then
			local timePosition = latestSong.TimePosition
			local crossfade = latestSong:GetAttribute("Crossfade")
			if(timePosition >= crossfade) then
				startNewSong = true
			end
		else
			startNewSong = true
		end
	else
		local song = script:FindFirstChildWhichIsA("Sound")
		if(song) then song:Destroy() end
		startNewSong = true
	end
end

local function resetScreen()
	if(not assigning) then
		if(roundUI) then roundUI:Destroy() end
		handleAllCharacters()
		adjustLighting("lobby")
		Player.CameraMode = Enum.CameraMode.Classic
		SurvivorVision.TintColor = Color3.fromRGB(255, 255, 255)
		SurvivorBlur.Size = 0
		disconnectRoleConnections()
	end
end

Angels:onSet(function(key, oldValue, newValue)
	if key ~= nil and typeof(key) == 'instance' then
		handleCharacterWithRole(key, "Angel")
	end	
end)

Survivors:onSet(function(key, oldValue, newValue) 
	if key ~= nil and typeof(key) == 'instance' then
		handleCharacterWithRole(key, "Survivor")
	end	
end)

handleAllCharacters()

RoleCommunication.packets.RoleAction.listen(function(action : string)
	if(currentRole) then
		if(currentRole == 'Angel') then
			if(action == 'heatsense') then
				heatsenseActive = not heatsenseActive
				local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, 0)
				for character, _ in Survivors:getStorage() do
					character = ClientDataCreator.getInstanceFromUUID(character, true)
					local highlight : Highlight = character:FindFirstChildWhichIsA("Highlight")
					if(highlight) then
						local outlineTransparency = (heatsenseActive and 0.1) or 1
						local fillTransparency = (heatsenseActive and 0.5) or 1
						local tween = TweenService:Create(highlight, tweenInfo, {
							OutlineTransparency=outlineTransparency,FillTransparency=fillTransparency
						})
						tween:Play()
					end
				end
			end	
		end
	end
end)

RoleCommunication.packets.Freeze.listen(function(freeze : boolean)
	if(currentRole) then
		local data = ClientDataCreator.get(currentRole, Player.Character)
		if(not data) then return end
		for _, part : BasePart in data:getObject():GetDescendants() do
			task.spawn(function()
				if(part:IsA("BasePart")) then
					part.Anchored = freeze
				end
			end)
		end
	end
end)

RoleCommunication.packets.RoleChange.listen(function(role : string)
	currentRole = nil
	resetScreen()
	
	assigning = true
	local firstCharacter = role:sub(1, 1):upper()
	role = firstCharacter..role:sub(2)
	loopAndPlayMusic(Sounds.RoundMusic:GetChildren())
	currentRole = role
	roundUI = script.RoundUI:Clone()
	roundUI.Common.Visible = true
	
	local data = ClientDataCreator.get(role, Player.Character, 5)
	Player.CameraMode = Enum.CameraMode.LockFirstPerson
	
	adjustLighting("round")
	
	data:listen("dead", died)

	roundUI.Parent = Player.PlayerGui
	assigning = false
	
	if(role == 'Survivor') then
		roundUI.Survivor.Visible = true
		local mainFrame = roundUI.Survivor
		local blinkFrame = mainFrame.Blink
		local mobileList = mainFrame.MobileList
		local half1 : ImageLabel = blinkFrame.Half1
		local half2 : ImageLabel = blinkFrame.Half2
		local maxDifference = 0.2
		local maxValue = data:getValue("maxBlinkMeter")
		local tweenInfo = TweenInfo.new(
			0.2,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out,
			0,
			false
		)
		local keyCodes = {
			[Enum.KeyCode.Q] = 'blink',
			[Enum.KeyCode.ButtonB] = 'blink',
			[Enum.KeyCode.Space] = 'strain',
			[Enum.KeyCode.ButtonA] = 'strain'
		}
		data:listen("blinking", function(oldValue, newValue) 
			local half1Tween, half2Tween, tweenBlinkFrame
			if newValue then
				local scale = half2.Position.Y.Scale
				local amountInChange =  (maxDifference - (1 - scale)) / maxDifference
				local tweenInfo = TweenInfo.new(
					math.max(0.3 * amountInChange, 0.2),
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.Out,
					0,
					false
				)

				half1Tween = TweenService:Create(half1, tweenInfo, {Position = UDim2.fromScale(half1.Position.X.Scale, -0.32)})
				half2Tween = TweenService:Create(half2, tweenInfo, {Position = UDim2.fromScale(half2.Position.X.Scale, 0.32)})
				tweenBlinkFrame = TweenService:Create(blinkFrame, tweenInfo, {BackgroundTransparency = 0})
			else
				half1Tween = TweenService:Create(half1, tweenInfo, {Position = UDim2.fromScale(half1.Position.X.Scale, -1)})
				half2Tween = TweenService:Create(half2, tweenInfo, {Position = UDim2.fromScale(half2.Position.X.Scale, 1)})
				tweenBlinkFrame = TweenService:Create(blinkFrame, tweenInfo, {BackgroundTransparency = 1})
			end

			half1Tween:Play()
			half2Tween:Play()
			tweenBlinkFrame:Play()
			tweenBlinkFrame.Completed:Once(function()
				SurvivorVision.TintColor = Color3.fromRGB(255, 255, 255)
				SurvivorBlur.Size = 0
			end)
		end)
		
		data:listen("blinkMeter", function(oldValue, newValue)
			if(newValue > 0 and newValue < maxValue) then
				local difference = (maxDifference) * ((maxValue - newValue) / maxValue)
				local half1Dif, half2Dif = -(1 - difference), 1 - difference
				local half1Tween = TweenService:Create(half1, tweenInfo, {Position = UDim2.fromScale(half1.Position.X.Scale, half1Dif)})
				local half2Tween = TweenService:Create(half2, tweenInfo, {Position = UDim2.fromScale(half2.Position.X.Scale, half2Dif)})

				half1Tween:Play()
				half2Tween:Play()

				SurvivorVision.TintColor = Color3.fromRGB(255, (SurvivorVision.TintColor.G * 255) - 1, (SurvivorVision.TintColor.G * 255) - 1)
				SurvivorBlur.Size = SurvivorBlur.Size + 0.1
			end
		end)
		addRoleConnection(UserInputService.InputBegan:Connect(function(inputObj, gpe)
			if not gpe or table.find(gpeWhitelist, inputObj.KeyCode) then
				local actionForKeyCode = keyCodes[inputObj.KeyCode]
				if(actionForKeyCode) then
					RoleCommunication.packets.RoleAction.send(actionForKeyCode)
				end
			end
		end))
		
		if(UserInputService.TouchEnabled) then
			mobileList.Visible = true
			addRoleConnection(mobileList.Spam.TouchTap:Connect(function()
				RoleCommunication.packets.RoleAction.send('strain')
			end))
			addRoleConnection(mobileList.ManualBlink.TouchTap:Connect(function()
				RoleCommunication.packets.RoleAction.send('blink')
			end))
		end
	elseif role == 'Angel' then
		roundUI.Angel.Visible = true
		script.AngelLight:Clone().Parent = Player.Character.HumanoidRootPart
		
		local animator : Animator = Player.Character.Humanoid:FindFirstChildWhichIsA("Animator") or Instance.new("Animator", Player.Character.Humanoid)
		local tracks = {}
		for _, animation in AngelAnimations:GetChildren() do
			table.insert(tracks, animator:LoadAnimation(animation))
		end
		local mainFrame = roundUI.Angel
		local list = mainFrame.List
		local mobileList = mainFrame.MobileList
		local bar = list.Bar
		
		local maxValue = data:getValue("maxEnergyMeter")
		
		local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, 0)
		
		local keyCodes = {
			[Enum.KeyCode.Space] = 'main',
			[Enum.KeyCode.E] = 'secondary',
			[Enum.KeyCode.ButtonA] = 'main',
			[Enum.KeyCode.ButtonB] = 'secondary'
		}
		
		data:listen("energyMeter", function(oldValue, newValue)
			if(newValue >= 0 and newValue < maxValue) then
				local percentage = 1 - (newValue / 100)
				local energyTween = TweenService:Create(bar.UIGradient, tweenInfo, {Offset = Vector2.new(0, percentage)})

				energyTween:Play()
			end
		end)
		
		addRoleConnection(UserInputService.InputBegan:Connect(function(inputObj, gpe)
			if not gpe or table.find(gpeWhitelist, inputObj.KeyCode) then
				local actionForKeyCode = keyCodes[inputObj.KeyCode]
				if(actionForKeyCode) then
					RoleCommunication.packets.UseAbility.send({abilityType=actionForKeyCode, toggled=true})
				end
			end
		end))
		
		addRoleConnection(UserInputService.InputEnded:Connect(function(inputObj, gpe)
			if not gpe or table.find(gpeWhitelist, inputObj.KeyCode) then
				local actionForKeyCode = keyCodes[inputObj.KeyCode]
				if(actionForKeyCode) then
					RoleCommunication.packets.UseAbility.send({abilityType=actionForKeyCode, toggled=false})
				end
			end
		end))

		if(UserInputService.TouchEnabled) then
			mobileList.Visible = true
			
			addRoleConnection(mobileList.MainAbility.TouchTap:Connect(function()
				RoleCommunication.packets.UseAbility.send({abilityType="main"})
			end))
			addRoleConnection(mobileList.SecondaryAbility.TouchTap:Connect(function()
				RoleCommunication.packets.UseAbility.send({abilityType="secondary"})
			end))
		end
		
		loopTracks(tracks)
	end
	
	-- we track our own watching table
	local lastSeen = {}
	local watching = {}
	local timeWeSent = nil
	local lastTimeAngelSpotted = nil
	local waitTillSpotSFX = 20
	
	local lastJumpScare = nil
	local jumpScareCooldown = 0.3
	
	local knownFlickering = {}
	local playingFlickerSound : Sound = nil
	local currentMusicVolume = 0.5
	
	addRoleConnection(RunService.RenderStepped:Connect(function()
		if not data.metadata.active or data:getValue("blinking") then watching = {} return end
		if not Player.Character:FindFirstChild("HumanoidRootPart") then return end

		for key, value in Angels:getStorage() do
			key = ClientDataCreator.getInstanceFromUUID(key)
			if not Player.Character:FindFirstChild("HumanoidRootPart") then return end

			if(key ~= nil and key ~= Player.Character) then
				local angelCharacter : Model = key :: Model
				local raycastParams = RaycastParams.new()
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude
				raycastParams:AddToFilter(Player.Character)
				raycastParams:AddToFilter(visionExcludables:getStorage(true))
				
				local angel = ClientDataCreator.get("Angel", angelCharacter)
				if not Player.Character:FindFirstChild("HumanoidRootPart") then return end

				if angel and not angel:getValue("dead") and (Util.playerSeesPart(angelCharacter.HumanoidRootPart) or Util.partSeesPart(Player.Character.HumanoidRootPart, angelCharacter.HumanoidRootPart)) and Util.partRaycastsToPart(Player.Character.HumanoidRootPart, angelCharacter.HumanoidRootPart, raycastParams) then
					task.spawn(function()
						if(currentRole == 'Survivor') then
							if(angel:getValue("frozen")) then
								if(not lastJumpScare or os.clock() - lastJumpScare > jumpScareCooldown) then
									if(lastSeen[angelCharacter.HumanoidRootPart]) then
										local lastPosition = lastSeen[angelCharacter.HumanoidRootPart]
										local currentPosition = angelCharacter.HumanoidRootPart.Position
										local distance = (currentPosition - lastPosition).Magnitude
										if(distance > Settings:GetAttribute("DistanceNeededForJumpscare")) then
											local jumpscare : Sound = Sounds.Jumpscare:GetChildren()[math.random(1, #Sounds.Jumpscare:GetChildren())]
											playNewSoundAndRemove(jumpscare:Clone())
											lastJumpScare = os.clock()
										end
									else
										local jumpscare : Sound = Sounds.Jumpscare:GetChildren()[math.random(1, #Sounds.Jumpscare:GetChildren())]
										playNewSoundAndRemove(jumpscare:Clone())
										lastJumpScare = os.clock()
									end
								end
								
								if(not lastTimeAngelSpotted or os.clock() - lastTimeAngelSpotted > waitTillSpotSFX) then
									local randomSpot : Sound = Sounds.Spotted:GetChildren()[math.random(1, #Sounds.Spotted:GetChildren())]
									playNewSoundAndRemove(randomSpot:Clone())
								end
								lastSeen[angelCharacter.HumanoidRootPart] = angelCharacter.HumanoidRootPart.Position
								lastTimeAngelSpotted = os.clock()
							end
						end
					end)
					
					if(table.find(watching, angelCharacter)) then continue end
					table.insert(watching, angelCharacter)
					RoleCommunication.packets.WatchingAngels.send(watching)
					timeWeSent = os.clock()
					print("SEE")
				else
					local i = table.find(watching, angelCharacter)
					if(i) then
						table.remove(watching, i)
						RoleCommunication.packets.WatchingAngels.send(watching)
						timeWeSent = os.clock()
						print("NO LONGER SEE")
					end
				end
			end
		end
		
		if(currentRole == "Survivor") then
			task.spawn(function()
				for key, value in Lights:getStorage() do
					key = ClientDataCreator.getInstanceFromUUID(key, true)
					if(key ~= nil) then
						local light = ClientDataCreator.get("Light", key)
						if(light and light:getValue("flickering")) then
							local raycastParams = RaycastParams.new()
							raycastParams.FilterType = Enum.RaycastFilterType.Exclude
							raycastParams:AddToFilter(Player.Character)
							raycastParams:AddToFilter(visionExcludables:getStorage(true))
							
							if((Util.playerSeesPart(key) or Util.partSeesPart(Player.Character.Head, key)) and Util.partRaycastsToPart(Player.Character.HumanoidRootPart, key, raycastParams)) then
								local find = table.find(knownFlickering, key)
								if(not find) then
									table.insert(knownFlickering, key)
								end
							end
						else
							local find = table.find(knownFlickering, key)
							if(find) then
								table.remove(knownFlickering, find)
							end
						end
					end
				end

				if(#knownFlickering > 0) then
					if(not playingFlickerSound) then
						playingFlickerSound = Sounds.FlickerScare:GetChildren()[math.random(1, #Sounds.FlickerScare:GetChildren())]:Clone()
						playingFlickerSound.Looped = true
						playingFlickerSound.Parent = script
						playingFlickerSound:Play()
					end
					playingFlickerSound.Volume = 0.5
					currentMusicVolume = math.max(0, currentMusicVolume - 0.003)
				elseif(playingFlickerSound) then
					currentMusicVolume = math.min(0.5, currentMusicVolume + 0.003)
					playingFlickerSound.Volume -= 0.003
					if(playingFlickerSound.Volume <= 0) then playingFlickerSound:Destroy() playingFlickerSound = nil end
				end
				
				for _, music : Sound in musicSounds do
					music.Volume = currentMusicVolume
				end
			end)
		end
		
		if(timeWeSent) then
			if(os.clock() - timeWeSent > 0.6) then
				RoleCommunication.packets.WatchingAngels.send(watching)
				timeWeSent = os.clock()
			end
		end
	end))
	
	handleAllCharacters()
end)

local lastAmbiencePlayed = nil
local nextAmbienceCooldown = nil

RunService.Heartbeat:Connect(function()
	loopAndPlayMusic(Sounds.RoundMusic:GetChildren())
	
	if(currentRole and Player.Character) then
		local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
		if(hrp) then
			if(not lastAmbiencePlayed or os.clock() - lastAmbiencePlayed > nextAmbienceCooldown) then
				local cooldown : string = Settings:GetAttribute("AmbienceCooldown")
				local minAndMax = cooldown:split(",")
				nextAmbienceCooldown = math.random(minAndMax[1], minAndMax[2])
				lastAmbiencePlayed = os.clock()
				local jimmy = Instance.new("Part")
				jimmy.Anchored = true
				jimmy.CanCollide = false
				jimmy.Transparency = 1
				jimmy.Size = Vector3.new(1, 1, 1)

				local position = {
					x = hrp.Position.X,
					y = hrp.Position.Y,
					z = hrp.Position.Z
				}
				
				local randomSFXPosition : string = Settings:GetAttribute("RandomSFXPosition")
				local minAndMax = randomSFXPosition:split(",")
				local min = minAndMax[1]
				local max = minAndMax[2]

				jimmy.Position = Vector3.new(
					position.x + math.random(min, max),
					position.y + math.random(min, max),
					position.z + math.random(min, max) 
				)
				
				jimmy.Parent = workspace
				
				local randomAmbience : Sound = Sounds.StoneSFX:GetChildren()[math.random(1, #Sounds.StoneSFX:GetChildren())]
				playNewSoundAndRemove(randomAmbience:Clone())
			end
		end
	else
		lastAmbiencePlayed = nil
		nextAmbienceCooldown = nil
	end
end)

Player.CharacterAdded:Connect(resetScreen)
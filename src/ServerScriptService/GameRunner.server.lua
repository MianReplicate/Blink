----------------------
-- Name: ConstantRunner
-- Authors: MianReplicate
-- Created: 1/10/2025
-- Purpose: To handle rounds and game mechanics every frame
----------------------
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RModules = ReplicatedStorage:WaitForChild("Modules")
local Util = require(RModules:WaitForChild("Util"))
local Modules = script.Parent:WaitForChild("Modules")
local GameLibrary = require(Modules:WaitForChild("GameLibrary"))
local DataCreator = require(Modules:WaitForChild("DataCreator"))
local RoleCommunication = require(RModules:WaitForChild("RoleCommunication"))
local ServerUtil = require(Modules:WaitForChild("ServerUtil"))
local AI = require(Modules:WaitForChild("AI"))

local aiList = DataCreator.get("List", "AI")
local lightExcludables = DataCreator.get("List", "LightExcludables")
local visionExcludables = DataCreator.get("List", "VisionExcludables")
local roundData = DataCreator.new("Round", "Data")
roundData:setValue("timer", 0)
roundData:setValue("state", nil)
roundData:setKeyChecks({"timer"}, function() return true, true end)
roundData:setAccessCheck(function() return true end)

local function excludeIfLightTransparent(basePart : BasePart)
	if(basePart.Transparency >= 0.75) then
		if(not lightExcludables:findValue(basePart)) then
			lightExcludables:addValue(basePart)
		end
	else
		local i = lightExcludables:findValue(basePart)
		if(i) then
			lightExcludables:removeValue(i)
		end
	end
end

local function excludeIfVisionTransparent(basePart : BasePart)
	if(basePart.Transparency > 0.07) then
		if(not visionExcludables:findValue(basePart)) then
			visionExcludables:addValue(basePart)
		end
	else
		local i = visionExcludables:findValue(basePart)
		if(i) then
			visionExcludables:removeValue(i)
		end
	end
end

local function loopForInstance(instance)
	if(instance:IsA("Accessory")) then
		lightExcludables:addValue(instance)
		visionExcludables:addValue(instance)
	elseif(instance:IsA("BasePart")) then
		excludeIfVisionTransparent(instance)
		excludeIfLightTransparent(instance)
		instance:GetPropertyChangedSignal("Transparency"):Connect(function()
			excludeIfVisionTransparent(instance)
			excludeIfLightTransparent(instance)
		end)
	end
end

for _, thing in workspace:GetDescendants() do
	loopForInstance(thing)
end

workspace.DescendantAdded:Connect(loopForInstance)

local function commonRole(data : (GameLibrary.Survivor | GameLibrary.Angel))
	local dataFromData = data:getData()
	local hasPlayer = dataFromData:getValue("player")
	local character = dataFromData:getObject()
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	
	if(humanoid) then
		if(humanoid.Health <= 0) then
			data:kill()
		end
		
		-- is this a non-player character :O
		if(hasPlayer) then
			local time = dataFromData:getValue("watchingAngelsTime")
			if((time and os.clock() - time > 0.8) or dataFromData:getValue("blinking") or dataFromData:getValue("dead")) then
				dataFromData:setValue("watchingAngelsTime", nil)

				ServerUtil.removeWatchingAngelsForCharacter(character)
			end
		else
			for _, angel in GameLibrary.getAngels(true) do
				if(angel and angel:getData() ~= dataFromData) then
					local beingWatchedBy = angel:getData():getValue("beingWatchedBy") :: DataCreator.Data
					local raycastParams = RaycastParams.new()
					raycastParams.FilterType = Enum.RaycastFilterType.Exclude
					raycastParams:AddToFilter(character)
					raycastParams:AddToFilter(visionExcludables:getStorage(true))
					if((not dataFromData:getValue("dead") and not dataFromData:getValue("blinking")) and Util.partSeesPart(character.HumanoidRootPart, angel:getData():getObject().HumanoidRootPart, true, nil, raycastParams)) then
						if(not beingWatchedBy:findValue(character)) then
							beingWatchedBy:addValue(character)
						end
					else
						local i = beingWatchedBy:findValue(character)
						if(i) then
							beingWatchedBy:setValue(i, nil)
						end
					end
				end
			end
		end
	end
end

RunService.Heartbeat:Connect(function()
	
	local lights = GameLibrary.getLights()
	for model, light in lights do
		local data = light:getData()
		local bulb = light:getBulb()
		
		local angels = GameLibrary.getAngels()
		local foundAngelToFlicker = false
		for character, angel in angels do
			if(light:isNearbyLight(character) and angel:isAbilityEnabled("main") and angel:isAlive()) then
				light:setStrengthModifier(character, -angel:getData():getValue("flickerStrength"))
				foundAngelToFlicker = true
				--shouldFlicker = true
			else
				light:removeStrengthModifier(character)
			end
		end
		
		light:editFlickerReason("angel", foundAngelToFlicker)
		
		local shouldFlicker = light:shouldFlicker()
		light:queueFlicker(shouldFlicker)
		
		-- local strengthOfLight = light:getStrength(true)
		if(shouldFlicker) then
			local flickerSfx : Sound = data:getValue("flickerSfx")
			local newVolume = flickerSfx.Volume
			local strain = light:getStrengthModifier("strain") or 0
			strain-=0.01
			--strain = math.max(-50, strain)
			light:setStrengthModifier("strain", strain)
			
			local lastToggled = data:getValue("lastToggled")
			if(not lastToggled or os.clock() - lastToggled > .05) then
				local enableRoll = light:roll()
				local enabled = bulb.Enabled
				if(not enabled) then
					-- make it harder for the light to turn on when turned off
					bulb.Enabled = enableRoll > 90
					newVolume -= 0.03
				else
					bulb.Enabled = enableRoll > 25
					newVolume += 0.01
				end
				
				data:setValue("lastToggled", os.clock())
			end

			local brightnessRoll = light:roll()
			local max = 1
			local min = 0
			
			--print(brightnessRoll, strain)
			local newBrightness = 0
			if(brightnessRoll >= 60) then
				newBrightness += math.random(1, 5) / 100
				newVolume += 0.01
			else
				newBrightness -= math.random(1, 2 + math.abs(strain)) / 100
				newVolume -= 0.01
			end
			local current = bulb.Brightness + newBrightness
			bulb.Brightness = math.min(max, math.max(min, current))
			flickerSfx.Volume = newVolume
		else
			data:setValue("lastToggled", nil)
			local strain = light:getStrengthModifier("strain") or 0
			strain += 0.01
			strain = math.min(0, strain)
			light:setStrengthModifier("strain", strain)
			
			local brightness = bulb.Brightness
			brightness += 0.005
			brightness = math.min(brightness, 1)
			
			bulb.Brightness = brightness
			bulb.Enabled = true
		end
	end
	
	local survivors = GameLibrary.getSurvivors(true)
	for character, survivor in survivors do
		local humanoid : Humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if(humanoid) then
			local walkDirection = Util.getWalkDirection(humanoid)
			if(walkDirection.Y < 0) then
				humanoid.WalkSpeed = 10
			else
				humanoid.WalkSpeed = 16
			end
		end
		
		local data = survivor:getData()
		local startStrain = data:getValue("straining")
		if(startStrain) then
			local deltaTime = os.clock() - startStrain
			if(deltaTime >= data:getValue("strainTime")) then
				local newValue = math.max(data:getValue("blinkMeter") - data:getValue("drainAmount"), 0)
				--print(newValue)
				survivor:setBlinkMeter(newValue)
				
				if(data:getValue("blinkMeter") <= 0) then
					data:setValue("straining", nil)
					survivor:blink()
				else
					startStrain = data:setValue("straining", os.clock())
				end
			end
		elseif data:getValue("blinking") then
			survivor:blink()
		end
		
		commonRole(survivor)
	end
	
	local angels = GameLibrary.getAngels(true)
	for character, angel in angels do
		local humanoid : Humanoid = character:FindFirstChildWhichIsA("Humanoid")
		local data = angel:getData()
		
		local beingWatchedBy = data:getValue("beingWatchedBy")
		angel:editFreezeReason("watched", Util.length(beingWatchedBy:getStorage()) > 0)
		angel:editFreezeReason("inLight", angel:isInAVisibleLight())

		if(humanoid) then

			local newWalkSpeed
			if(angel:shouldBeFrozen("watched", "inLight")) then
				--print("FROZE")
				data:setValue("canKill", false)
				if(not data:getValue("timeOfFreeze")) then
					data:setValue("timeOfFreeze", os.clock())
				end
				local plr = data:getValue("player")
				if(plr) then
					RoleCommunication.packets.Freeze.sendTo(true, plr)
				end
				newWalkSpeed = 0
				
				if(os.clock() - data:getValue("timeOfFreeze") > 0.4) then
					for _, part : BasePart in character:GetDescendants() do
						if(part:IsA("BasePart")) then
							part.Anchored = true
						end
					end
				end
				data:setValue("frozen", true)
			else
				local minWalkSpeed = data:getValue("minWalkSpeed")
				local maxWalkSpeed = data:getValue("maxWalkSpeed")
				local difference = maxWalkSpeed - minWalkSpeed

				local energy = data:getValue("energyMeter")
				local maxEnergy = data:getValue("maxEnergyMeter")
				local percentage = energy / maxEnergy

				newWalkSpeed = minWalkSpeed + (percentage * difference)
				
				if(data:getValue("timeOfFreeze")) then
					local pos = Vector3.new(character.HumanoidRootPart.Position.X, character.HumanoidRootPart.Position.Y + 0.01, character.HumanoidRootPart.Position.Z)
					--print("UNFROZE")
					if character.HumanoidRootPart.Anchored then -- If not anchored, likely the walkspeed was just 0 only.
						character.HumanoidRootPart.Position = pos
					end
					
					local plr = data:getValue("player")
					if(plr) then
						RoleCommunication.packets.Freeze.sendTo(false, plr)
					end
					
					for _, part : BasePart in character:GetDescendants() do
						if(part:IsA("BasePart")) then
							part.Anchored = false
						end
					end
					if((character.HumanoidRootPart.Position - pos).Magnitude < 8) then
						data:setValue("canKill", true)
						data:setValue("timeOfFreeze", nil)
						data:setValue("frozen", false)
					end
				end
			end
			
			angel:setWalkSpeed(newWalkSpeed)
		end
		
		local lightCount = Util.length(angel:getNearbyLights())
		local possibleFlickerStrength = data:getValue("baseFlickerStrength") / lightCount
		data:setValue("flickerStrength", possibleFlickerStrength)
		
		for _, ability in angel:getAbilities() do
			if(ability.onFrame) then
				ability.onFrame()
			end
			if(ability.toggled) then
				local currentUseTime = ability.currentUseTime
				if(currentUseTime) then
					if(ability.drainEverySetTime) then
						if(os.clock() - currentUseTime > ability.drainEverySetTime) then
							ability.currentUseTime = os.clock()
							angel:increaseEnergy(-ability.drain)
						end
					end
				else
					ability.currentUseTime = os.clock()
				end
			else
				ability.currentUseTime = nil
			end
		end

		--print(angel:isAllowedToKill(), angel:shouldBeFrozen("watched", 'inLight'), beingWatchedBy:getStorage(), angel:isInAVisibleLight())
		
		if(data:getValue("energyMeter") <= 0) then
			angel:kill()
		end
		
		commonRole(angel)
	end
	
	for _, ai : DataCreator.Data in aiList:getStorage() do
		local goals = ai:getValue("Goals")
		local goalsRun = nil --{}
		for name, goal in goals do
			local success = goal(ai, goalsRun)
			Util.assert(success ~= nil, `{name} did not return whether it was successful or not. Your goal is bugged bruh.`)
			if(success) then break end
			--goalsRun[name] = success
		end
	end
	-- handle timer here :sunglasses:	
end)
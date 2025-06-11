local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ServerScriptService:WaitForChild("Modules")
local RModules = ReplicatedStorage:WaitForChild("Modules")
local RoleCommunication = require(RModules:WaitForChild("RoleCommunication"))
local DataCreator = require(Modules:WaitForChild("DataCreator"))
local Util = require(RModules:WaitForChild("Util"))
local Sounds = ReplicatedStorage:WaitForChild("Sounds")

local lights = DataCreator.newOrGet("List", "Lights")
local lightExcludables = DataCreator.newOrGet("List", "LightExcludables")

local light = {}

function light:isOn()
	local lightInstance = self:getBulb()
	return lightInstance.Enabled and lightInstance.Brightness > 0
end

function light:getPosition()
	local data : DataCreator.Data = self:getData()
	local lightInstance = data:getObject()
	local posToUse = lightInstance.Position

	if(not lightInstance:IsDescendantOf(workspace)) then
		local model = data:getValue("model")
		if(model:IsA("Tool")) then
			-- figure out an alternative backpack solution for npcs
			local backpack : Backpack = model.Parent
			if(backpack and backpack:IsA("Backpack")) then
				local player = backpack.Parent
				local chr = player.Character
				if(chr and chr:FindFirstChild("HumanoidRootPart")) then
					posToUse = chr.HumanoidRootPart.Position
				end
			end
		end
	end

	return posToUse
end

function light:isNearbyLight(character : Model)
	local data : DataCreator.Data = self:getData()
	local lightInstance = data:getObject()
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if(hrp) then
		local bulb : PointLight | SurfaceLight | SpotLight = self:getBulb()
		local magnitude = (self:getPosition() - hrp.Position).Magnitude

		return magnitude < bulb.Range + 6
	end
end

function light:isInLight(character : Model)
	local data : DataCreator.Data = self:getData()
	local lightInstance = data:getObject()
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if(hrp and lightInstance:IsDescendantOf(workspace)) then
		local bulb : PointLight | SurfaceLight | SpotLight = self:getBulb()
		local magnitude = (self:getPosition() - hrp.Position).Magnitude

		-- implement different checks for different types of light
		if(magnitude < bulb.Range) then
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams:AddToFilter(data:getValue("model"))
			raycastParams:AddToFilter(lightExcludables:getStorage(true))

			if(data:getValue("bulbType") == 'around') then
				return Util.partRaycastsToPart(data:getObject(), hrp, raycastParams)
			else
				return Util.partSeesPart(data:getObject(), hrp, true, bulb.Angle)
			end
		end
	end
end

function light:getStrengthModifier(modifierIdentifier : any)
	local data : DataCreator.Data = self:getData()
	local strengthModifiers = data:getValue("strengthModifiers")
	return strengthModifiers[modifierIdentifier]
end

function light:setStrengthModifier(modifierIdentifier : any, modifierValue : number)
	local data : DataCreator.Data = self:getData()
	local strengthModifiers = data:getValue("strengthModifiers")
	strengthModifiers[modifierIdentifier] = modifierValue
end

function light:removeStrengthModifier(modifierIdentifier : any)
	local data : DataCreator.Data = self:getData()
	local strengthModifiers = data:getValue("strengthModifiers")
	strengthModifiers[modifierIdentifier] = nil
end

function light:getStrengthModifiers()
	local data : DataCreator.Data = self:getData()
	local strength = 0
	local strengthModifiers = data:getValue("strengthModifiers")
	for _, num in strengthModifiers do
		strength += num
	end
	return strength
end

function light:getStrength(modifiersApplied : boolean) : number
	local data : DataCreator.Data = self:getData()
	local strength = data:getValue("baseStrength")
	if(modifiersApplied) then
		strength += self:getStrengthModifiers()
	end

	return strength
end

function light:roll()
	local roll = math.random(0, 100)

	local strength = self:getStrength(true)
	roll += strength

	local strengthWithoutBase = self:getStrengthModifiers()
	local randomStrengthRoll = math.random(-math.abs(strengthWithoutBase), math.abs(strengthWithoutBase))
	roll += randomStrengthRoll

	roll = math.max(0, math.min(100, roll))

	return roll
end

function light:editFlickerReason(reason : string, active : bool)
	local data : DataCreator.Data = self:getData()

	local flicker : DataCreator.Data = data:getValue("flicker")
	if(flicker) then
		if(active) then
			if(not table.find(flicker, reason)) then table.insert(flicker, reason) end
		else
			local index = table.find(flicker, reason)
			if(index) then 
				table.remove(flicker, index)
			end
		end
	end
end

function light:shouldFlicker(... : string)
	local data : DataCreator.Data = self:getData()

	local reasons = {...}
	local flicker : {string} = data:getValue("flicker")
	local test = true
	
	if(#reasons > 0) then
		for _, reason in reasons do
			test = table.find(flicker, reason) ~= nil
			if(not test) then break end
		end
	else
		return #flicker > 0
	end

	return test
end

-- Handled by ConstantRunner
function light:queueFlicker(start : boolean)
	local data : DataCreator.Data = self:getData()
	if(data:getValue("flickering") == start) then return end
	
	if(start) then
		local flickering = Sounds.Flickering:GetChildren()
		local flickerSfx : Sound = flickering[math.random(1, #flickering)]:Clone()
		flickerSfx.Parent = data:getObject()

		data:setValue("flickerSfx", flickerSfx)
		flickerSfx:Play()
		flickerSfx.Volume = 0 -- start at 0
		flickerSfx.Looped = true
	else
		local flickerSfx = data:getValue("flickerSfx")

		if(flickerSfx) then
			flickerSfx:Destroy()
			data:setValue("flickerSfx", nil)
		end
	end
	data:setValue("flickering", start)
end

function light:getBulb() : (PointLight | SurfaceLight | SpotLight)
	return self:getData():getValue("bulb")
end

function light:remove()
	local data : DataCreator.Data = self:getData()
	lights:setValue(data:getObject(), nil)
	data:remove()
	table.freeze(self)
	self = nil
end

function light:resetValues()
	local data : DataCreator.Data = self:getData()
	data:setValue("baseStrength", 25)
	data:setValue("strengthModifiers", {})
	data:setValue("flickering", false)
	data:setValue("flicker", {})
	--data:setValue("lastToggled", nil)
end

function light:getData() : DataCreator.Data
	return self.data
end

return light
----------------------
-- Name: GameLibrary
-- Authors: MianReplicate
-- Created: 12/31/2024
-- Purpose: To make it easy for other scripters to do shit
----------------------
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local WeepingAngels = ServerStorage:WaitForChild("WeepingAngels"):WaitForChild("V3")
local RModules = ReplicatedStorage:WaitForChild("Modules")
local RoleCommunication = require(RModules:WaitForChild("RoleCommunication"))
local DataCreator = require(script.Parent:WaitForChild("DataCreator"))

local Util = require(RModules:WaitForChild("Util"))
local rCord = require(RModules:WaitForChild("rCord"))
local AngelAnimations = ReplicatedStorage:WaitForChild("AngelAnimations")
local SurvivorAnimations = ReplicatedStorage:WaitForChild("SurvivorAnimations")
local Sounds = ReplicatedStorage:WaitForChild("Sounds")
local webhook = rCord.createWebhook("https://discord.com/api/webhooks/1324287648465948682/iMlVDZWXl6sds4HMQ-JGQcRR0U7HB_JEoUXrnhIIGOjQenbuRRvXZc0nLPHZ4c-7yQMe")

local angel = require(script.Angel)
local survivor = require(script.Survivor)
local light = require(script.Light)
local tool = require(script.Tool)

local roundRagdolls : {Model} = {}

local survivors = DataCreator.newOrGet("List", "Survivors")
local angels = DataCreator.newOrGet("List", "Angels")
local lights = DataCreator.newOrGet("List", "Lights")
local tools = DataCreator.newOrGet("List", "Tools")
local lightExcludables = DataCreator.newOrGet("List", "LightExcludables")
local visionExcludables = DataCreator.newOrGet("List", "VisionExcludables")

visionExcludables:setKeyChecks({}, function() return true, true end, true)
visionExcludables:setAccessCheck(function() return true end)
survivors:setKeyChecks({}, function() return true, false end, true)
survivors:setAccessCheck(function() return true end)
angels:setKeyChecks({}, function() return true, false end, true)
angels:setAccessCheck(function() return true end)
lights:setKeyChecks({}, function() return true, false end, true)
lights:setAccessCheck(function() return true end)

local gameLibrary = {}

function gameLibrary.getWebhook()
	return webhook
end

function gameLibrary.getSurvivors(hasToBeAlive : boolean?) : Survivors
	local storage = survivors:getStorage()
	local realStorage = {}
	for character, survivor in storage do
		local instance = DataCreator.getInstanceFromUUID(character)
		if(not instance) then continue end
		if(hasToBeAlive ~= true or (hasToBeAlive and not survivor:getData():getValue("dead"))) then
			realStorage[instance] = survivor
		end
	end
	return realStorage
end

function gameLibrary.getAngels(hasToBeAlive : boolean?) : Angels
	local storage = angels:getStorage()
	local realStorage = {}
	for character, angel in storage do
		local instance = DataCreator.getInstanceFromUUID(character)
		if(not instance) then continue end
		if(hasToBeAlive ~= true or (hasToBeAlive and not angel:getData():getValue("dead"))) then
			realStorage[instance] = angel
		end
	end
	return realStorage
end

function gameLibrary.getLights() : Lights
	local storage = lights:getStorage()
	local realStorage = {}
	for instance, light in storage do
		local _instance = DataCreator.getInstanceFromUUID(instance)
		if(not _instance) then continue end
		realStorage[instance] = light
	end
	return realStorage
end

function gameLibrary.createOrGetSurvivor(character : Model, player : Player?) : Survivor
	local foundSurvivor = survivors:getValue(character)
	if(foundSurvivor) then return foundSurvivor :: Survivor end
	
	local humanoid : Humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local animator : Animator = humanoid:FindFirstChild("Animator") :: Animator
	if(not animator) then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0
	humanoid.BreakJointsOnDeath = false
	
	local survivor : Survivor = Util.deepClone(survivor)

	local data = DataCreator.new("Survivor", character)
	data:setValue("blinking", false)
	data:setValue("allowedFunctions", {"blink", "strain"})
	
	--data:listen("blinkMeter", function(oldValue, newValue)
	--	if(newValue <= 0) then
	--		survivor:blink()
	--	end
	--end)
	
	survivor.data = data
	survivor.blinkTrack = animator:LoadAnimation(SurvivorAnimations.Blink:Clone())
	survivor:resetValues()
	survivor:queueStraining(true)
	
	if(player) then
		data:setValue("player", player)

		local function isOwner(player : Player)
			return player == data:getValue("player"), true
		end

		data:setKeyChecks({"blinking", "blinkMeter", "dead", "maxBlinkMeter"}, isOwner)
		data:setAccessCheck(isOwner)
	end
	
	survivors:setValue(character, survivor)
	
	character.Archivable = true
	return survivor
end

function gameLibrary.createOrGetAngel(character : Model, player : Player?) : Angel
	local foundAngel = angels:getValue(character)
	if(foundAngel) then return foundAngel :: Angel end

	local humanoid : Humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local animator : Animator = humanoid:FindFirstChild("Animator") :: Animator
	if(not animator) then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0
	humanoid.BreakJointsOnDeath = false

	local angel : Angel = Util.deepClone(angel)
	
	local data = DataCreator.new("Angel", character)
	local beingWatchedBy = DataCreator.new("BeingWatchedBy", character)
	data:setValue("beingWatchedBy", beingWatchedBy)
	data:setValue("freeze", {})

	angel:setData(data)
	angel:resetValues()
	
	for _, part in character:GetChildren() do
		-- is the part a basepart and is angel frozen?
		if(part:IsA("BasePart")) then
			part = part :: BasePart
			part.Touched:Connect(function(otherPart : BasePart)
				if not angel:isAllowedToKill() or otherPart.Parent == nil then return end
				
				-- check if that character is behind a wall or not
				local potentialSurvivor = otherPart.Parent
				if potentialSurvivor:IsA("Model") and potentialSurvivor:FindFirstChild("Humanoid") then
					local survivor = gameLibrary.getRoleDataFromCharacter(potentialSurvivor, "Survivor") :: Survivor
					if(survivor and not survivor:getData():getValue("dead") and otherPart.Name ~= "Handle" and (humanoid.RootPart.Position - otherPart.Position).Magnitude < 5 and Util.partRaycastsToPart(humanoid.RootPart, otherPart)) then
						survivor:kill()
					end
				end
			end)
		end
	end
	
	if player then
		data:setValue("player", player)

		local function isOwner(player : Player)
			return player == data:getValue("player"), true
		end

		data:setKeyChecks({"maxEnergyMeter", "energyMeter", "abilities"}, isOwner)
	end
	
	data:setKeyChecks({"frozen", "dead"}, function() return true end)
	data:setAccessCheck(function() return true end)
	
	angels:setValue(character, angel)
	return angel
end

function gameLibrary.createOrGetLight(lightModel : Model, lightPart : BasePart) : GameLight
	local foundLight = lights:getValue(lightPart)
	if foundLight then return foundLight :: GameLight end
	
	local lightBulb = lightPart:FindFirstChildWhichIsA("PointLight", true) or lightPart:FindFirstChildWhichIsA("SurfaceLight", true) or lightPart:FindFirstChildWhichIsA("SpotLight", true)
	Util.assert(lightBulb, `No lightbulb found for light part {lightPart}`)
	
	local bulbType = {
		PointLight = "around",
		SpotLight = "focused",
		SurfaceLight = "focused"
	}
	
	local light : GameLight = Util.deepClone(light)
	
	local data = DataCreator.new("Light", lightPart)
	
	data:setValue("model", lightModel)
	data:setValue("bulb", lightBulb)
	data:setValue("bulbType", bulbType[lightBulb.ClassName])
	
	data:setKeyChecks({"flickering"}, function() return true, true end)
	data:setAccessCheck(function() return true end)
	
	light:setData(data)
	light:resetValues()
	
	lights:setValue(lightPart, light)
	return light
end

function gameLibrary.createOrGetTool(tool : GameTool, toolType : string)
	local foundTool = tools:getValue(tool)
	if(foundTool) then return foundTool :: GameTool end
	
	local tool : GameTool = Util.deepClone(tool)

	local data = DataCreator.new("Tool", tool)
	data:setValue("")
end

function gameLibrary.changeIntoRole(player : Player, role : string, optionalPosition : CFrame) : Angel | Survivor
	local validRoles : {[string]:RoleCreator} = {
		survivor = {
			create = gameLibrary.createOrGetSurvivor, 
			newCharacter = function() 
				player:LoadCharacter()
				return player.Character or player.CharacterAdded:Wait()
			end
		}, 
		angel = {
			create = gameLibrary.createOrGetAngel,
			newCharacter = function()
				local randomAngel = WeepingAngels:GetChildren()[math.random(1, #WeepingAngels:GetChildren())]:Clone()
				player.Character = randomAngel
				randomAngel.Parent = workspace
				return randomAngel
			end,
		}
	}
	role = role:lower()
	local validRole = validRoles[role]
	Util.assert(validRole, `{role} is not a valid role!`)
	
	local character = player.Character
	local oldPos
	if(character and character:FindFirstChild("HumanoidRootPart")) then
		oldPos = character.HumanoidRootPart.CFrame
		local existingData : Angel | Survivor = gameLibrary.getRoleDataFromCharacter(character)
		if(existingData) then
			existingData:remove()
		end
	end
	
	local posToUse = optionalPosition or oldPos
	
	local character : Model = validRole.newCharacter()
	local roleData : Angel | Survivor = validRole.create(character, player)
	
	if(posToUse) then
		character.HumanoidRootPart.CFrame = posToUse
	end

	RoleCommunication.packets.RoleChange.sendTo(role, player)
	return roleData
end

function gameLibrary.getRoleDataFromCharacter(character : Model, specificRole : string?) : Angel | Survivor
	local roles = {
		angel = angels,
		survivor = survivors
	}
	
	if(specificRole) then
		return roles[specificRole:lower()]:getValue(character)
	end
	
	return survivors:getValue(character) or angels:getValue(character)
end

function gameLibrary.cleanUpRagdolls()
	for _, ragdoll in roundRagdolls do
		ragdoll:Destroy()
	end
end

type RoleCreator = {
	create : (character : Model, player : Player) -> Angel | Survivor,
	newCharacter : () -> Model
}

export type Survivor = typeof(survivor)
export type Angel = typeof(angel)
export type GameLight = typeof(light)
export type GameTool = typeof(tool)

export type Survivors = {[Model]:Survivor}
export type Angels = {[Model]:Angel}
export type Lights = {[Instance]:GameLight}
export type Tools = {[Tool]:GameTool}

return gameLibrary
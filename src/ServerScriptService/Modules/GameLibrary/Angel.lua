local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ServerScriptService:WaitForChild("Modules")
local RModules = ReplicatedStorage:WaitForChild("Modules")
local RoleCommunication = require(RModules:WaitForChild("RoleCommunication"))
local DataCreator = require(Modules:WaitForChild("DataCreator"))
local Util = require(RModules:WaitForChild("Util"))
local ServerUtil = require(Modules:WaitForChild("ServerUtil"))
local AngelAnimations = ReplicatedStorage:WaitForChild("AngelAnimations")
local Sounds = ReplicatedStorage:WaitForChild("Sounds")

local lights = DataCreator.newOrGet("List", "Lights")
local angels = DataCreator.newOrGet("List", "Angels")

local function getLights()
	local storage = lights:getStorage()
	local realStorage = {}
	for instance, light in storage do
		local _instance = DataCreator.getInstanceFromUUID(instance)
		if(not _instance) then continue end
		realStorage[instance] = light
	end
	return realStorage
end

local angel = {}

function angel:editFreezeReason(reason : string, active : boolean)
	local data = self:getData()

	if(data:getValue("dead")) then return end

	local freeze : {string} = data:getValue("freeze")
	if(freeze) then
		if(active) then
			if(not table.find(freeze, reason)) then table.insert(freeze, reason) end
		else
			local index = table.find(freeze, reason)
			if(index) then 
				table.remove(freeze, index)
			end
		end
	end
end

function angel:shouldBeFrozen(... : string)
	local data = self:getData()

	if(data:getValue("dead")) then return end

	local reasons = {...}
	local freeze : {string} = data:getValue("freeze")
	local test = true
	
	if(#reasons > 0) then
		for _, reason in reasons do
			test = table.find(freeze, reason) ~= nil
			if(not test) then break end
		end
	else
		return #freeze > 0
	end

	return test
end

function angel:isAllowedToKill()
	local data = self:getData()

	if(data:getValue("dead")) then return end

	return data:getValue("canKill")
end

function angel:setWalkSpeed(walkSpeed : number)
	local data = self:getData()

	if(data:getValue("dead")) then return end

	local character : Model = data:getObject()
	local humanoid : Humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed = walkSpeed
end

function angel:increaseEnergy(energy : number)
	local data = self:getData()

	if(data:getValue("dead")) then return end
	local value = data:getValue("energyMeter")
	value += energy
	value = math.max(0, math.min(value, data:getValue("maxEnergyMeter")))
	
	data:setValue("energyMeter", value)
end

function angel:increaseEnergyOnKill()
	local data = self:getData()

	if(data:getValue("dead")) then return end
	
	self:increaseEnergy(data:getValue("energyOnKill"))
end

function angel:getNearbyLights()
	local data = self:getData()

	if(data:getValue("dead")) then return end
	local lights = {}

	for _, light in getLights() do
		if(light:isNearbyLight(data:getObject())) then
			table.insert(lights, light)
		end
	end

	return lights
end

function angel:isInAVisibleLight()
	local data = self:getData()

	if(data:getValue("dead")) then return end

	for _, light in getLights() do
		if(light:isInLight(data:getObject()) and light:isOn()) then
			print(light:getData():getValue("model"))
		
			return true
		end
	end

	return false
end

function angel:isNearbyLight()
	local data = self:getData()

	if(data:getValue("dead")) then return end

	for _, light in getLights() do
		if(light:isNearbyLight(data:getObject())) then
			return true
		end
	end

	return false
end

function angel:isAbilityEnabled(typeOfAbility : string)
	local data = self:getData()
	if(data:getValue("dead")) then return end
	
	local abilities : {Ability} = data:getValue("abilities")
	local num = (typeOfAbility == 'main' and 1) or (typeOfAbility == 'secondary' and 2)
	
	return abilities[num].toggled
end

function angel:toggleAbility(typeOfAbility : string, enable : boolean)
	local data = self:getData()
	if(data:getValue("dead")) then return end
	
	local abilities : {Ability} = data:getValue("abilities")
	local num = (typeOfAbility == 'main' and 1) or (typeOfAbility == 'secondary' and 2)
	local ability = abilities[num]
	local state = ability.toggled
	
	if(enable == nil) then
		enable = not state -- toggle functionality
	end
	
	if(enable == false or not ability.lastUsed or (os.clock() - ability.lastUsed > ability.useCooldown)) then 
		ability.toggled = enable
		if(enable) then
			ability.lastUsed = os.clock()
			if(not ability.drainEverySetTime) then
				self:increaseEnergy(-ability.drain)
			end
		end
		if(ability.onToggle) then
			ability.onToggle(enable)
		end
	end
end

function angel:getAbilities() : {Ability}
	local data = self:getData()
	if(data:getValue("dead")) then return {} end
	
	return data:getValue("abilities")
end

function angel:isAlive()
	local data = self:getData()
	return not data:getValue("dead")
end

function angel:kill()
	local data = self:getData()
	if(not data:getValue("dead")) then
		data:setValue("dead", true)
		ServerUtil.removeWatchingAngelsForCharacter(data:getObject())
		local tempBox = Instance.new("Part")
		data:setValue("tempBox", tempBox)
		
		local randomCrumble = Sounds.Crumble:GetChildren()[math.random(1, #Sounds.Crumble:GetChildren())]:Clone()
		randomCrumble.Parent = tempBox
		
		tempBox.Position = data:getObject().HumanoidRootPart.Position
		tempBox.Anchored = true
		tempBox.CanCollide = false
		tempBox.Transparency = 1
		tempBox.Size = Vector3.new(1, 1, 1)
		
		local position = {
			x = tempBox.Size.X / 2,
			y = tempBox.Size.Y / 2,
			z = tempBox.Size.Z / 2,
		}

		for i = 1, 40, 1 do
			local smallBoi = Instance.new("Part")
			smallBoi.Size = Vector3.new(0.2, 0.2, 0.2)
			smallBoi.Position = tempBox.Position + Vector3.new(
				math.random(-position.x * 10, position.y * 10) / 10,
				math.random(-position.y * 10, position.y * 10) / 10,
				math.random(-position.z * 10, position.z * 10) / 10
			)
			smallBoi.Material = Enum.Material.Concrete
			smallBoi.Parent = tempBox
		end
		
		data:getObject():Destroy()
		tempBox.Parent = workspace
		
		randomCrumble:Play()

		local player : Player = data:getValue("player")
		if(player) then
			task.spawn(pcall, function()
				task.wait(Players.RespawnTime)
				if(not player.Character or not player.Character:IsDescendantOf(game)) then
					player:LoadCharacter()
				end
			end)
		end
	end
end

function angel:remove()
	local data = self:getData()
	angels:setValue(data:getObject(), nil)
	local tempBox = data:getValue("tempBox")
	if(tempBox) then tempBox:Destroy() end
	data:remove()
	table.freeze(self)
	self = nil
end

-- Reset values to their default, used on initial creation
function angel:resetValues()
	local data = self:getData()
	data:setValue("maxEnergyMeter", 100)
	data:setValue("energyMeter", data:getValue("maxEnergyMeter"))

	data:setValue("minWalkSpeed", 18)
	data:setValue("maxWalkSpeed", 25)

	data:setValue("energyOnKill", 10)
	data:setValue("canKill", true)

	--data:setValue("inLight", {})
	data:setValue("abilities", {
		-- function and then whether it is enabled or disabled
		{
			name="Flicker", 
			drain=10,
			toggled=false,
			drainEverySetTime = 1,
			useCooldown = 0
		},
		{
			name="Heatsense",
			drain=25,
			toggled = false,
			useCooldown = 10,
			onToggle = function(toggled : boolean)
				if(toggled) then
					RoleCommunication.packets.RoleAction.sendTo("heatsense",data:getValue("player"))
					task.wait(4)
					RoleCommunication.packets.RoleAction.sendTo("heatsense",data:getValue("player"))
				end
			end,
		}
	})
	data:setValue("baseFlickerStrength", 6)
	data:setValue("flickerStrength", data:getValue("baseFlickerStrength"))
	--data:setValue("flickerableLights", {})

	-- how long we'll wait for the client to give anchor positions
	--data:setValue("waitTimeForAnchor", 0.3)
end

-- Returns the data for this angel
function angel:getData() : DataCreator.Data
	return self.data
end

function angel:setData(data : DataCreator.Data)
	self.data = data
end

export type Ability = {
	name : string,
	drain : number,
	toggled : boolean,
	currentUseTime : number,
	drainEverySetTime : number,
	lastUsed : number,
	useCooldown : number,
	onToggle : ((toggled : boolean) -> ())?,
	onFrame : (() -> ())?
}

return angel
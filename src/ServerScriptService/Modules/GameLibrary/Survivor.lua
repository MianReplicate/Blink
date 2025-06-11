local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ServerScriptService:WaitForChild("Modules")
local RModules = ReplicatedStorage:WaitForChild("Modules")
local RoleCommunication = require(RModules:WaitForChild("RoleCommunication"))
local DataCreator = require(Modules:WaitForChild("DataCreator"))
local ServerUtil = require(Modules:WaitForChild("ServerUtil"))
local Util = require(RModules:WaitForChild("Util"))
local SurvivorAnimations = ReplicatedStorage:WaitForChild("SurvivorAnimations")
local Sounds = ReplicatedStorage:WaitForChild("Sounds")

local survivors = DataCreator.newOrGet("List", "Survivors")

local survivor = {}

-- Makes the Survivor blink
function survivor:blink()
	local data : DataCreator.Data = self:getData()
	local track = self.blinkTrack :: AnimationTrack
	if(not data:getValue("dead")) then
		if(not data:getValue("blinking")) then
			self:queueStraining(false)
			data:setValue("strainTime", data:getValue("blinkResetTimer") / 2)
			self:setBlinkMeter(0) -- for the sake of eye animation
			self:resetValues()
			data:setValue("blinking", os.clock())
		else
			local delta = os.clock() - data:getValue("blinking")
			if(delta >= data:getValue("blinkResetTimer")) then
				data:setValue("blinking", nil)
				self:setBlinkMeter(data:getValue("blinkMeter")) -- for the sake of eye animation
				self:queueStraining(true)
			end
		end
	end
end

-- Start straining a Survivor's eyes
-- @param start : Whether to start or stop straining
function survivor:queueStraining(start : boolean)
	local data : DataCreator.Data = self:getData()

	if(data:getValue("dead")) then return end

	if(start) then
		data:setValue("straining", os.clock())
	else
		data:setValue("straining", nil)
	end
end

-- Lets the survivor strain their eyes for slightly longer, increasing the meter but also making their eyes strain faster
function survivor:strain()
	local data : DataCreator.Data = self:getData()

	if(data:getValue("dead")) then return end

	if data:getValue("blinkMeter") < data:getValue("maxBlinkMeter") and data:getValue("strainIncrease") > 0 and not data:getValue("blinking") then
		self:setBlinkMeter(data:getValue("blinkMeter") + data:getValue("strainIncrease"))
		data:setValue("strainIncrease", math.max(data:getValue("strainIncrease") - 0.6, data:getValue("minStrainIncrease")))
		data:setValue("strainTime", math.max(data:getValue("strainTime") - 0.04, data:getValue("minStrainTime")))
	end
end

-- Sets the blink meter to a new value. This also changes the face animation
-- @param newValue : The value to change to
function survivor:setBlinkMeter(newValue : number)
	local data : DataCreator.Data = self:getData()

	if(data:getValue("dead")) then return end

	data:setValue("blinkMeter", math.min(newValue, data:getValue("maxBlinkMeter")))
	local track = self.blinkTrack :: AnimationTrack
	local trackTime = math.min(1 - (newValue / data:getValue("maxBlinkMeter")), 0.99)
	--track.TimePosition = trackTime
	local useTime = (newValue == 100 and data:getValue("blinkResetTimer") / 2) or data:getValue("strainTime")
	local tInfo = TweenInfo.new(useTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false, 0)
	local tweenToPosition = TweenService:Create(track, tInfo, {TimePosition = trackTime})
	if(not track.IsPlaying) then
		track:Play()
		track:AdjustSpeed(0)
	end
	tweenToPosition:Play()
end

function survivor:isAlive()
	local data : DataCreator.Data = self:getData()
	return not data:getValue("dead")
end

-- Kills the survivor
function survivor:kill()
	local data : DataCreator.Data = self:getData()
	if(not data:getValue("dead")) then
		data:setValue("dead", true)
		ServerUtil.removeWatchingAngelsForCharacter(data:getObject())

		local character : Model = data:getObject()
		local clone = character:Clone()
		character:Destroy()
		local humanoid : Humanoid = clone:WaitForChild("Humanoid")
		-- avoid HRP colliding with UpperTorso on death
		--clone.HumanoidRootPart.CanCollide = false

		clone.Parent = workspace

		for _, instance : Instance in clone:GetDescendants() do
		--	if(instance:IsA("BasePart")) then
		--		--part:SetNetworkOwner(nil)
		--		instance.Anchored = false

		--		if(instance ~= clone.HumanoidRootPart and not instance.Parent:IsA("Accessory") and instance.Name ~= "Handle") then
		--			instance.CanCollide = true
		--		end
			if instance:IsA("BaseScript") then
				instance:Destroy()
		--	elseif instance:IsA("AnimationConstraint") then
		--		if(instance.Parent == clone.Head) then continue end

		--		instance.Enabled = false
		--	elseif instance:IsA("BallSocketConstraint") then
		--		--instance.MaxFrictionTorque = 1
			end
		end
		
		--humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		--humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		--humanoid:ChangeState(Enum.HumanoidStateType.Dead)
		humanoid.Health = 0
		humanoid.AutoJumpEnabled = false

		data:setValue("ragdoll", clone)

		for _, track : AnimationTrack in humanoid.Animator:GetPlayingAnimationTracks() do
			track:Stop()
		end

		local track : AnimationTrack = humanoid.Animator:LoadAnimation(SurvivorAnimations.Dead:Clone())
		track:Play()
		track:AdjustSpeed(0)
		track.TimePosition = 0.99

		local snaps : {Sound} = Sounds.Snaps:GetChildren()
		local randomSnap = snaps[math.random(1, #snaps)]:Clone()
		randomSnap.Parent = clone.Head
		randomSnap:Play()

		local player : Player = data:getValue("player")
		if(player) then
			task.spawn(pcall, function()
				task.wait(Players.RespawnTime)
				if(not player.Character:IsDescendantOf(game)) then
					player:LoadCharacter()
				end
			end)
		end
	end
end

-- Removes the survivor
function survivor:remove()
	local data : DataCreator.Data = self:getData()
	survivors:setValue(data:getObject(), nil)
	local ragdoll : Model = data:getValue("ragdoll")
	if(ragdoll) then
		ragdoll:Destroy()
	end
	data:remove()
	table.freeze(self)
	self = nil
end

-- Reset values to their default, used when the Survivor blinks
function survivor:resetValues()
	local data : DataCreator.Data = self:getData()
	data:setValue("maxBlinkMeter", 100)
	data:setValue("blinkMeter", data:getValue("maxBlinkMeter"))
	data:setValue("blinkResetTimer", .3)

	data:setValue("drainAmount", 10)

	data:setValue("straining", nil)
	data:setValue("strainTime", 1)
	data:setValue("minStrainTime", 0.2)

	data:setValue("strainIncrease", 15)
	data:setValue("minStrainIncrease", 0)
end

-- Returns the data for this survivor
function survivor:getData() : DataCreator.Data
	return self.data
end

export type Survivor = typeof(survivor)

return survivor
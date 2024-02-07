----------------------
-- Name: RoleData
-- Authors: LoxiGoose
-- Created: 12/4/2023
-- Last Updated: 12/12/2023
----------------------
local RunService = game:GetService("RunService")
local roleData = {}
roleData.__index = roleData

local roleDataTypes = {
	["Survivor"] = function(roleData)
			pcall(function()
			roleData:setMultipleData({
				blinkMeter = {
					maxValue = 100,
					value = 100
				},
				blinkDrainAmount = 10,
				blinkIncreaseAmount = {
					minValue = 0,
					value = 15
				},
				blinkDrainTime = {
					minValue = 0.2,
					value = 1
				},
				sprintMeter = {
					maxValue = 100,
					value = 100
				},
				blinking = false,
				blink = function()
					if roleData:getData("blinking") then return end
					local oldTexture = roleData:getData("character").Head.face.Texture
					roleData:setData("blinking", true, true)
					roleData:activateFunction("stopBlinkDrain")
					print("Blinking!")
					roleData:getData("character").Head.face.Texture = "http://www.roblox.com/asset/?id=15324447"
					task.wait(0.3)
					roleData:setMultipleData({
						blinkMeter = {
							maxValue = 100,
						},
						blinkDrainAmount = 10,
						blinkIncreaseAmount = {
							minValue = 0,
							value = 15
						},
						blinkDrainTime = {
							minValue = 0.2,
							value = 1
						},
					})
					roleData:getData("character").Head.face.Texture = oldTexture
					roleData:setData("value", 100, true, "blinkMeter")
					roleData:activateFunction("startBlinkDrain")
					roleData:setData("blinking", false, true)
				end,
				startBlinkDrain = function()
					local drainThread = coroutine.create(function()
						print("HI")
						while roleData:getData("value", "blinkMeter") > 0 do
							task.wait(roleData:getData("value", "blinkDrainTime"))
							print(1)
							roleData:setData("value", math.max(roleData:getData("value", "blinkMeter") - roleData:getData("blinkDrainAmount"), 0), true, "blinkMeter")
							if roleData:getData("value", "blinkMeter") <= 0 then
								roleData:activateFunction("blink", true) -- Have to run in a separate thread otherwise it errors
							end
						end
					end)
					
					roleData:setData("blinkDrainingThread", drainThread)
					coroutine.resume(roleData:getData("blinkDrainingThread"))
				end,
				stopBlinkDrain = function()
					task.cancel(roleData:getData("blinkDrainingThread"))
					roleData:setData("blinkDrainingThread", nil)
				end,
				keepEyesOpen = function()
					if roleData:getData("value", "blinkMeter") < roleData:getData("maxValue", "blinkMeter") and not roleData:getData("blinking") then
						roleData:setData("value", math.min(roleData:getData("value", "blinkMeter") + roleData:getData("value", "blinkIncreaseAmount"), roleData:getData("maxValue", "blinkMeter")), true, "blinkMeter")
						roleData:setData("value", math.max(roleData:getData("value", "blinkIncreaseAmount") - 0.5, roleData:getData("minValue", "blinkIncreaseAmount")), false, "blinkIncreaseAmount")
						roleData:setData("value", math.max(roleData:getData("value", "blinkDrainTime") - 0.02, roleData:getData("minValue", "blinkDrainTime")), false, "blinkDrainTime")
					end
				end,
				startSprint = function()

				end,
				stopSprint = function()

				end,
			})
			roleData:activateFunction("startBlinkDrain")
			
			roleData:onClientFunctionFire("keepEyesOpen", "blink")
			roleData:setAllowedValues(
				{"blinkMeter", "maxValue"},
				{"blinkDrainTime", "value"}
			)

			print("Set up SurvivorData!")
		end)

		-- If we don't exist anymore, remove everything needed below here

			--[[
	TODO:
	1. Sprinting
	2. Death screen + Death sound (Death sound should be heard for everyone)
	3. Survivor animations (Walking)
	4. Controls for PC + Mobile
	]]

	end,
	["Weeping Angel"] = function(roleData)
		roleData:setMultipleData({
			seeingPlayers = {

			},
			useAbility = function(abilityName : string)
				-- TODO: Script this in mind of Angels having multiple abilities: flickering, seeing through walls, etc
			end,
		})

			--[[
	TODO:
	1. Purple Vision (Client-sided purple light that has a bit of range)
	2. Kill players when touched
	3. Freeze when looked at
	4. (Ability) See people through walls
	5. (Ability) Flicker
	6. Death (Crumbling sound, random stones spawning around)
	7. Swap Animations When Unfrozen
	8. User-Interface
	9. Controls for PC + Mobile
	]]
	end,
}

function roleData:activateFunction(functionName, coroutineWrap, ...)
	local func = self[functionName]
	if func and typeof(func) == "function" then
		local function handleFunction()
			local success, errormsg = pcall(func)
			if (not self.inactive and not success) or RunService:IsStudio() then
				error(errormsg)
			end
		end
		
		if coroutineWrap then
			coroutine.wrap(handleFunction)()
		else
			handleFunction()
		end
	elseif not self.inactive then
		error("Unknown function: "..functionName)
	end
end

function roleData:setData(index, value, replicate, ...)
	if self.inactive then return setmetatable(self, nil) end
	
	local parent = self
	if ... then
		if typeof(...) == 'table' then
			for _, valueindex in ... do
				parent = parent[valueindex]
			end
		else
			parent = parent[...]
		end
	end

	parent[index] = value

	if replicate then
		self:sendInfoToClient({{...}, index, value})
	end
end

function roleData:setMultipleData(tableofData, replicate)
	if self.inactive then return setmetatable(self, nil) end
	
	for index, value in tableofData do
		self:setData(index, value, replicate)
	end
end

function roleData:getData(index, ...)
	if self.inactive then return setmetatable(self, nil) end
	
	local parent = self
	if ... then
		if typeof(...) == 'table' then
			for _, valueindex in ... do
				parent = parent[valueindex]
			end
		else
			parent = parent[...]
		end
	end
	return parent[index]
end

-- Only needed for player. This is just so players can have data for UI
function roleData:sendInfoToClient(...)
	if self.inactive then return setmetatable(self, nil) end
	
	if self:getData("player") then
		self.remoteEvent:FireClient(self:getData("player"), ...)
	end
end

-- Only if we need some sort of data from the player
function roleData:onClientFire(func)
	if self.inactive then return setmetatable(self, nil) end
	local conn
	conn = self.remoteEvent.OnServerEvent:Connect(function(player, ...)
		if self.inactive then conn:Disconnect() return end

		if player == self:getData("player") then
			func(...)
		else
			player:Kick("You nerd, stop tryna exploit")
		end
	end)
	return conn
end

function roleData:setAllowedValues(...)
	if self.inactive then return setmetatable(self, nil) end
	
	local allowedValues = {...}
	self.remoteFunction.OnServerInvoke = function(player, parents, index)
		if player == self:getData("player") then
			table.insert(parents, index)
			local foundMatch = false

			local function crawl(parents_)
				local foundMatch_
				if not table.find(parents_, index) then
					local foundCrawl = false
					for _, value in parents_ do
						if typeof(value) == 'table' then
							foundCrawl = true
							foundMatch_ = crawl(value)
						end
					end
					if not foundCrawl then
						foundMatch_ = false
					end
				else
					foundMatch_ = true
				end

				return foundMatch_
			end

			for _, parents_ in allowedValues do
				local foundMatch_ = crawl(parents_)
				if foundMatch_ then
					foundMatch = true
					break
				end
			end

			if foundMatch then
				table.remove(parents, table.find(parents, index))
				return self:getData(index, parents)
			else
				-- The requested values are not allowed to be given
				return nil
			end
		else
			player:Kick("You nerd, stop tryna exploit")
		end
	end
end

function roleData:onClientFunctionFire(...)
	if self.inactive then return setmetatable(self, nil) end

	local allowedValues = {...}
	local conn
	conn = self.remoteEvent.OnServerEvent:Connect(function(player, functionName, ...)
		if self.inactive then 
			conn:Disconnect() 
			return 
		end
		
		if player == self:getData("player") and table.find(allowedValues, functionName) then
			self:activateFunction(functionName, false, ...)
		else
			player:Kick("You nerd, stop tryna exploit")
		end
	end)
	return conn
end

function roleData:init(character : Model, roleDataType : string)
	if self:getData("initialized") then 
		error("Already initialized!") 
		return 
	end

	self:setData("initialized", true)
	self:setData("inactive", false)
	self:setData("character", character)
	self:setData("type", roleDataType)
	self.remoteEvent = Instance.new("RemoteEvent")
	self.remoteEvent.Name = "CommunicateEvent"
	self.remoteEvent.Parent = character
	self.remoteFunction = Instance.new("RemoteFunction")
	self.remoteFunction.Name = "GetDataFunction"
	self.remoteFunction.Parent = character
	
	roleDataTypes[roleDataType](self)
end

return roleData

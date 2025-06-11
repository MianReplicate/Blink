--!strict
----------------------
-- Name: DataRegistry
-- Authors: MianReplicate
-- Created: 6/27/2024
----------------------
local Players = game:GetService("Players")
local Data = require(script.Data)
local registry = {
	registered = false,
}
local privateRegistry = {}
local registeredTypes : {[string] : DataType} = {}

local dataType = {
	name = nil,
	activeDatas = {} :: {[any]:Data.Data},
	inactiveDatas = {} :: {[any]:Data.Data},-- ready to be garbage collected
	dataInfo = {} :: Data.DataInfo
}

local function crawlForSubtypes(subtypes)
	for name, subtype in subtypes do
		if typeof(subtype) == 'table' then
			shared.Utils.addEnum(`SubTypes.{name}`, true)
			crawlForSubtypes(subtype)
		end
	end
end

local function findSubtype(subtypes, subtypeString : string, currentInheritance : {string}?)
	currentInheritance = currentInheritance or {}
	for name, subtype in subtypes do
		if name == subtypeString and typeof(subtype) == 'table' then
			table.insert(currentInheritance, subtypeString)
			return subtype, currentInheritance
		elseif typeof(subtype) == 'table' then
			table.insert(currentInheritance, name)
			return findSubtype(subtype,subtypeString,currentInheritance)
		end
	end
end

export type Registry = typeof(registry)
export type DataType = typeof(dataType)
type RegisteredTypes = typeof(registeredTypes)

-- Removes an active data if it exists
-- @param The identifier for the created data
-- @param How long to keep this data inactive before it is removed
function dataType:removeDataIfExists(identifier : any, delay : number)
	local data = self:getData(identifier)
	if data then
		self:removeData(identifier, delay)
	end
end

-- Removes an active data
-- @param The identifier for the created data
-- @param How long to keep this data inactive before it is removed
function dataType:removeData(identifier : any, delay : number)
	local data = self:getData(identifier)
	assert(data, `{identifier} is not an active data in {self.name}`)

	data:setValue('inactive', true)
	self.activeDatas[identifier] = nil
	self.inactiveDatas[identifier] = data
	task.wait(delay or 0)
	data = self:getDataIncludingInactive(identifier)
	if data.inactive then -- Just in case the same inactive data was replaced by the same identifier for new data
		self.inactiveDatas[identifier] = nil
	end
end

-- Creates an active data
-- @param The identifier for the data
-- @param The subtype that belongs to this data. See Roles for an example of what subtypes look like
-- @return The active data
function dataType:createData(identifier : any, subtypeString : string) : Data.Data
	local subtype, inheritance = findSubtype(self.dataInfo.subTypes, subtypeString)
	assert(subtype, `{subtypeString} is not a valid subtype of {self.name}!`)
	assert(not self:getData(identifier), `{identifier} is already an active data within {self.name}`)

	local dataInfo : Data.DataInfo = shared.Utils.cloneDict(self.dataInfo)
	local data = Data(identifier, dataInfo)
	coroutine.wrap(function()
		local subtype = self.dataInfo.subTypes
		for i, name in inheritance do
			subtype = subtype[name]
			local success, errormsg = pcall(subtype.init, data)
			if i == #inheritance then
				table.remove(inheritance, i)
				if success then
					self.activeDatas[identifier] = data
					shared.debug(`Initialized subtype {subtypeString} from {self.name} using identifier {identifier} with inheritance {unpack(inheritance)}`)
				else
					self.activeDatas[identifier] = nil
					warn(`Failed to initialize subtype {subtypeString} from {self.name} using identifier {identifier} with inheritance {unpack(inheritance)}`)
					error(errormsg)
				end
			end
		end
	end)()
	return data
end

-- Gets an active data
-- @param The identifier for the data
-- @return The active data
function dataType:getData(identifier : any) : Data.Data?
	local data = self.activeDatas[identifier]
	return data
end

-- Gets a data regardless of its active state
-- @param The identifier for the data
-- @return The data
function dataType:getDataIncludingInactive(identifier : any)
	return self:getData(identifier) or self.inactiveDatas[identifier]
end

-- Gets all active datas
-- @return All active datas
function dataType:getDatas() : {[any]:Data.Data}
	return self.activeDatas
end

-- Gets all datas regardless of active state
-- @return all datas
function dataType:getDatasIncludingInactive() : {[any]:Data.Data}
	return {unpack(self.activeDatas), unpack(self.inactiveDatas)}
end

-- Tells you whether a subtype inherits another subtype or not
-- returns {number} - The index of when the subtype was inherited from
function dataType:isSubtypeOfSubtype(subtypeString, subtypeString1)
	local subtype, inheritance = findSubtype(self.subTypes, subtypeString)
	return table.find(inheritance, subtypeString1)
end

-- Returns the datatype wanted
-- @param The string that identifies the datatype
-- @return The datatype wanted
function registry.getType(identifier : string) : DataType
	local datatype = registry.getTypes()[identifier]
	if not datatype then
		error(`{identifier} is not registered as valid datatype!`)
	end
	return datatype
end


-- Returns all registered datatypes
-- @return All registered datatypes
function registry.getTypes() : RegisteredTypes
	assert(registry.registered, `Cannot retrieve active datatypes because my types have not been registered yet!`)
	return registeredTypes
end

-- Returns all registered datainfos
-- @param Exclude any datainfos that have their replicateType setting to false
-- @return All selected registered datainfos
function registry.getDataInfos(excludeNonReplicated : boolean) : RegisteredTypes
	assert(registry.registered, `Cannot retrieve registered datatypes because my types have not been registered yet!`)
	
	local fakeRegisteredTypes : RegisteredTypes = {}
	for name, dataType in registeredTypes do
		if(excludeNonReplicated and not dataType.dataInfo.settings.replicateType) then
			continue
		end
		
		fakeRegisteredTypes[name] = dataType.dataInfo
	end
	return fakeRegisteredTypes
end

-- Used to send a custom packet to the player(s). Only use if you cannot send a packet through an active data.
-- @param The players to send the packet to
-- @param The identifier for a datatype
-- @param The identifier for a subtype
-- @param The type of packet this is
-- @param Any additional arguments to pass
function registry.sendCustomPacket(players : {Player}?,datatype:string,subtype:string?,packettype:string,...)
	players = players or Players:GetPlayers()
	for _, player in players do
		shared.Utils.FireRemote("CommunicateEvent", player, {datatype=datatype,subtype=subtype,packettype=packettype}, ...)
	end
end

-- Register a datatype via datainfo returned from a module. YOU do not need to use this function, DataRegistry automatically registers all modules within itself. If you need an example for how a datatype module should look, see Roles.
-- @param A datatype in form of a module that returns datainfo
-- @returns Returns if the type successfully registered and an error if it did not
function privateRegistry.registerType(typeToRegister : ModuleScript) : boolean & any
	shared.debug(`Registering datatype {typeToRegister}`)
	local success, errormsg = pcall(function()
		assert(not registeredTypes[typeToRegister.Name], `Already registered {typeToRegister}!`)
		local dataInfo : Data.DataInfo = require(typeToRegister)
		assert(
			(dataInfo.subTypes and typeof(dataInfo.subTypes) == 'table') 
				and (dataInfo.packetTypes and typeof(dataInfo.packetTypes) == 'table'), 
			`{typeToRegister} is missing required values for a datatype!`)
		
		shared.Utils.addEnum(`DataTypes.{typeToRegister.Name}`)
		crawlForSubtypes(dataInfo.subTypes)
		for _, name in dataInfo.packetTypes do
			shared.Utils.addEnum(`PacketTypes.{name}`, true)
		end
		local dataType : DataType = shared.Utils.cloneDict(dataType)
		dataType.dataInfo = dataInfo
		
		registeredTypes[typeToRegister.Name] = dataType
	end)
	return success, errormsg
end

-- Registers all datatypes. THIS should ONLY be run once and should already be running in GameLibrary.
function registry.registerTypes()
	assert(not registry.registered, `Already registered types for DataRegistry!`)
	registry.registered = true
	shared.debug("Registering datatypes")
	for _, register : Instance in script.Data:GetChildren() do
		if(register:IsA("ModuleScript")) then
			local success, errormsg = privateRegistry.registerType(register)
			if not success then
				warn(`Failed to register datatype {register}`)
				error(errormsg)
			end	
		end
	end
end

-- Removes any datas that have removed instance as an identifier
game.DescendantRemoving:Connect(function(instance : Instance)
	local types = registry.getTypes()
	for datatypeName, datatype in types do
		task.spawn(function()
			datatype:removeDataIfExists(instance, 3) -- A sort of grace period in case other code needs to meddle with this data before it is gone
		end)
	end
end)

return registry :: Registry

--!strict
----------------------
-- Name: Data
-- Authors: MianReplicate
-- Created: 6/27/2024
--[[
Description:

The purpose of this module is to make creating information about an object easy for other scripts to retrieve with easy to use replication.
This is an abstract module that has to be inherited from another module in order to be used.

It is recommended to read the 'Roles' module if you need an example on how to use this module.
]]
----------------------
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Utils = shared.Utils

type ancestry = {any}

type requestableFunctionsForPlayers = {
	players : {Player},
	functions : {string}
}

type requestableIndexesForPlayers = {
	players : {Player},
	ancestries : {ancestry},
	editable : boolean
}

local data = {
	inactive = false,
	dataInfo = nil :: DataInfo,
	requestableIndexes = {} :: {[string]: requestableIndexesForPlayers},
	requestableFunctions = {} :: {[string]: requestableFunctionsForPlayers},
} do
	-- Runs a function without breaking script execution if it errors
	-- @param The wanted function to run safely
	-- @param Arguments to send to the function
	-- @return The return of the function being run if there was any
	function data:safelyRunFunc(func : (...any?) -> any?, ... : any?) : any?
		local success, returnValue = pcall(func, ...)
		if (not self.inactive and not success) then
			error(returnValue)
		end
		return returnValue
	end

	-- Activates a function with some added precautions
	-- @param The name of the function to run
	-- @param Whether to run this function on a separate thread or not
	-- @param Additional arguments to pass to the function
	-- @return The return of the function if there was any
	function data:activateFunction(functionName : string, async : boolean, ... : any?) : any?
		if self.inactive then return end

		local func = self[functionName]
		if func and typeof(func) == "function" then
			local _return
			if async then
				local args = ...
				task.spawn(function()
					_return = data:safelyRunFunc(func, args)
				end)
			else
				_return = data:safelyRunFunc(func, ...)
			end
			return _return
		elseif not self.inactive then
			error("Unknown function: "..functionName)
		end

		return
	end

	-- Sets an index to a value
	-- @param The index to change
	-- @param The value to put
	-- @param What players should be notified of this change
	-- @param The ancestors/parent of this index. Oldest ancestor starts on the first index if this is a table.
	function data:setValue(index : any, value : any, players : {Player}?, ... : any?)
		if self.inactive then return end
		if(index == 'identifier' or index == 'dataInfo') then
			assert(not self:getValue(index), "Cannot change already set identifier/metadata for this data: "..self.identifier)
		end

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

		local oldValue = parent[index]
		parent[index] = value

		if players then
			self:sendPacket(players, shared.Utils.retrieveEnum("PacketTypes.ValueChanged"), {ancestry={..., index}, oldValue=oldValue,newValue=value})
		end
	end
	
	-- Sets multiple values at a time from a table
	-- @param A table of indexes and values
	-- @param What players should be notified of this change
	function data:setMultipleValues(tableOfData : {[any]:any}, players : {Player}?)
		if self.inactive then return end
		for index : any, value : any in tableOfData do
			self:setValue(index, value, players)
		end
	end

	-- Retrieves a value from an index
	-- @param The identifier of the value
	-- @param The ancestors/parent of this index. Oldest ancestor starts on the first index.
	-- @return The value to return
	function data:getValue(index : any, ancestry : ancestry?) : any?
		if self.inactive then return end

		local parent = self
		ancestry = ancestry or {}
		for _, valueindex in ancestry do
			parent = parent[valueindex]
		end

		return parent[index]
	end

	-- Sends a packet to the client. This packet consists any data you may want to send and metadata such as datatype, subtype, and packettype.
	-- @param What players to send the packet to
	-- @param The type of packet this is. Any unregistered packet types sent through will error!
	-- @param Additional arguments to send
	function data:sendPacket(players : {Player}, packetType : string, ... : any?)
		if self.inactive then return end
		local datatypeinfo = self:getValue("datatypeinfo")
		assert((packetType and table.find(datatypeinfo.packettypes, packetType)) or packetType == shared.Utils.retrieveEnum("PacketTypes.ValueChanged"), `{packetType} is not a valid packet type for datatype {datatypeinfo.datatype}!`)
		players = players or Players:GetPlayers()
		for _, player in players do
			Utils.FireRemote("CommunicateEvent", player, {datatype=datatypeinfo.datatype,subtype=datatypeinfo.subtype,packetType=packetType}, ...)
		end
	end

	-- Creates a requestable list which is responsible for exposing indexes (alongside their values) to a select list of players. These lists can be updated with new players and functions.
	-- @param The name for this list in particular. Any existing lists get updated with the new info.
	-- @param The list of players that should be able to retrieve these indexes
	-- @param Whether the players can change the values of these indexes or not
	-- @param The list of values that are exposed. This consists of multiple tables that include the ancestry of the index. The oldest ancestor starts off with the first index. An example can be found in the Roles module if needed.
	function data:addRequestableIndexesFor(name : string, players : {Player}, editable : boolean, ... : ancestry)
		if self.inactive then return end

		local tble : requestableIndexesForPlayers = self.requestableIndexes[name] or {players = players, ancestries = {}, editable = editable}
		if ... then
			for _, ancestry in {...} do
				table.insert(tble.ancestries, ancestry)
			end
		end

		self.requestableIndexes[name] = tble
	end

	-- Creates a requestable list which is responsible for exposing functions to a select list of players. These lists can be updated with new players and functions.
	-- @param The name for this list in particular. Any existing lists get updated with the new info.
	-- @param The list of players
	-- @param A tuple list of function names that are allowed to be ran by the client
	function data:addRequestableFunctionsFor(name : string, players : {Player}, ... : string)
		if self.inactive then return end

		local tble : requestableFunctionsForPlayers = self.requestableFunctions[name] or {players = players, functions = {}}
		if ... then
			for _, funcName in {...} do
				table.insert(tble.functions, funcName)
			end
		end
		self.requestableFunctions[name] = tble
	end

	-- When a player requests a value from an index, this function returns it if they can see it
	-- @param The player requesting the value
	-- @param The ancestors of the index including the index. Oldest first to newest last.
	-- @param A value that the player wants to replace the old value with
	-- @return Returns the wanted value or a boolean if the player wanted to set a value
	function data:requestValueFor(player : Player, keyLocation : ancestry, newValue : any?) : (any | boolean)?
		if self.inactive then return end
		local foundMatch = false

		local function crawl(ancestry)
			for i, value in ancestry do
				if keyLocation[i] ~= value then
					return false
				end
			end

			return true
		end

		for listName, requestable in self.requestableIndexes do
			if table.find(requestable.players, player) then
				for _, ancestry in requestable.ancestries do
					foundMatch = crawl(ancestry)
					if foundMatch then
						break
					end
				end
				if foundMatch then
					local key = keyLocation[#keyLocation]
					table.remove(keyLocation, table.find(keyLocation, key))
					if newValue then
						self:setValue(key, newValue, nil, keyLocation)
						return true
					else
						return self:getValue(key, keyLocation)
					end
				end
			end
		end

		return false
	end

	-- When a player requests a function, this function determines if they are allowed to activate that function
	-- @param The player requesting the function to be called
	-- @param The name of the function to run
	-- @param Any arguments the player may send over
	-- @return Whether the function was activated or not
	function data:requestFunctionFor(player : Player, funcName : string, ... : any?) : boolean?
		if self.inactive then return end
		for listName, requestable in self.requestableFunctions do
			if table.find(requestable.players, player) then
				if table.find(requestable.functions, funcName) then
					self:activateFunction(funcName, false, ...)
					return true
				end
			end
		end

		return false
	end
	
	-- Retrieve metadata
	-- @return Returns metadata
	function data:getDataInfo() : DataInfo
		return self:getValue("dataInfo")
	end
end

export type Data = typeof(data)

type Inheritable = {
	init : (Data) -> (),
	[string] : Inheritable
}

export type DataType = {
	--[[
	A variant of the datatype that inherits from the data module. Each subtype has an init function which is called for the subtype when it is created.
Subtypes can inherit other subtypes. For example, if the subtype "Survivor" and subtype "Angel" both had a common piece of code for roles, you could create a subtype called "Common" and create an initialization function for that subtype. Then, you could create the subtypes "Survivor" and "Angel" below that subtype with their own initialization method. The code will automatically run the common init for both subtypes since they inherit common.
Your subtype name cannot be 'init' (obviously)
	]]
	subTypes : { 
		[string] : Inheritable
	},
	--[[
	Register packet types via strings for networking purposes
	]]
	packetTypes : {string},
	-- Currently, the only setting is 'replicateType', which is to determine if a client can see that the datatype exists or not.
	settings : {
		replicateType : boolean
	},
	dataType : string
}

export type DataInfo = {
	dataType : string
}


-- Creates a new data with its identifier and dataInfo. YOU should not be using this normally and should be creating data through DataRegistry.
-- @param The identifier for the data
-- @param Consists of datatype name, subtype name, and packettypes
return function(identifier : any, dataInfo : DataInfo) : Data
	assert(identifier and dataInfo, "Not all arguments were provided for creating a new data of type!")
	local data : Data = shared.Utils.cloneDict(data) :: Data
	data:setValue("dataInfo", dataInfo)
	data:setValue("identifier", identifier)
	
	return data
end
--!strict
----------------------
-- Name: DataCreator
-- Authors: MianReplicate
-- Created: 12/30/2024
-- Purpose: To handle and replicate known data about objects in a simple way
----------------------
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local GroupService = game:GetService("GroupService")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Util = require(Modules:WaitForChild("Util"))
local DataCommunication = require(Modules:WaitForChild("DataCommunication"))
local Types = require(Modules:WaitForChild("Types"))

local data = {
	storage = {} :: {[any]:any},
	metadata = {} :: Metadata
}

local helper = {}

export type TagToDatas = {[any]:{[any]:Data}}

local storages : {[string]:TagToDatas} = {
	default = {}
}

local UUIDsToInstances : {[string]:(Instance | nil)} | {} = {}

function data:isRunnable()
	Util.assert(self.metadata.active, `Cannot run functions on inactive data for object! {self.metadata.object}`)
end

-- Activate listeners for when a value has changed, typically you will not need to run this manually
-- @param key : What the value should be assigned to
-- @param oldValue : What the old value was
-- @param value : What the new value is
function data:valueChanged(key : any, oldValue : any?, value : any)
	self:isRunnable()
	local keyListeners = self:getMetadata().keyListeners[key]
	if(keyListeners) then
		for _, listener in keyListeners do
			listener(oldValue, value)
		end
	end
	
	for _, onSetListener in self:getMetadata().onSetListeners do
		onSetListener(key, oldValue, value)
	end
end

-- Run this when changing a value to replicate to players. This is called automatically when using the setValue and addValue functions
-- @param key : The key being used
-- @param value : The new value for the key
function data:replicateValueChange(key : any, value : any)
	for _, player in Players:GetPlayers() do
		if(self:testAccessCheck(player)) then
			local keySuccess, valueSuccess = self:testKeyCheck(player, key)
			if(keySuccess) then
				if(not valueSuccess) then
					value = 'notreplicated'
				end
				
				local valueChanged : Types.ValueChanged = {
					storageIdentifier=self:getStorageIdentifier(),
					tag=self:getTag(),
					object=self:getObject(true),
					key=key,
					value=value,
					version=self:getVersion()
				}
				Util.fireRemote("ValueChanged", player, valueChanged)
				--DataCommunication.packets.ValueChanged.sendTo(valueChanged, player)
			end
		end

		if(Util.isAdmin(player)) then
			local valueChanged : Types.ValueChanged = {
				storageIdentifier="admin",
				tag=self:getTag(),
				object=self:getObject(true),
				key=key,
				value=value,
				version=self:getVersion()
			}
			Util.fireRemote("ValueChanged", player, valueChanged)
			--DataCommunication.packets.ValueChanged.sendTo(valueChanged, player)
		end
	end
end

-- Assign a value to a key within the data
-- @param key : What the value should be assigned to
-- @param value : What you want to put within the data
function data:setValue(key : any, value : any)
	self:isRunnable()
	if(key and typeof(key) == 'Instance') then
		key = helper.generateOrGetExistingUUID(key)
	end

	if(value and typeof(value) == 'Instance') then
		value = helper.generateOrGetExistingUUID(value)
	end
	local oldValue = self.storage[key]
	if(oldValue == value) then return end
	self.storage[key] = value
	self:increaseVersion()
	self:replicateValueChange(key, value)
	task.spawn(self.valueChanged, self, key, oldValue, value)
end

-- Returns a value given a key. If the value is a UUID, then it will return the instance assigned with the UUID
-- @param key : What the value is assigned to
-- @return The value assigned to the key
function data:getValue(key : any) : any?
	self:isRunnable()
	key = helper.getUUIDFromInstance(key) or key
	local value : any = self.storage[key]
	local toReturn = (value and helper.getInstanceFromUUID(value)) or value
	return toReturn
end

-- Insert a value into the table as if it was numbered. This is similar to table.insert(data:getStorage(), value)
-- @param value : What value to add
function data:addValue(value : any)
	self:isRunnable()
	if(value and typeof(value) == 'Instance') then
		value = helper.generateOrGetExistingUUID(value)
	end
	local length = #self.storage
	self:setValue(length + 1, value)
	--table.insert(self.storage, value)
	self:valueChanged(length, nil, value)
end

function data:removeValue(index : any)
	self:isRunnable()
	table.remove(self.storage, index)
	self:valueChanged(index, nil, nil)
end

-- Find a value's index. This is similar to table.find(data:getStorage(), value)
-- @param value : The value to find
function data:findValue(value : any)
	self:isRunnable()
	if(value and typeof(value) == 'Instance') then
		value = helper.generateOrGetExistingUUID(value)
	end
	for i, v in self.storage do
		if(v == value) then 
			return i 
		end
	end
end

-- Returns the object assigned to this data
-- @param If you want the UUID assigned for the object instead
-- @return The object
function data:getObject(uuidForm: boolean)
	local object = self:getMetadata().object
	local toReturn
	if(uuidForm) then
		toReturn = object
	elseif(object) then
		toReturn = helper.getInstanceFromUUID(object) or object
	end
	return toReturn
end

-- Returns the tag
-- @return The tag
function data:getTag() : string
	return self:getMetadata().tag
end

-- Returns metadata about the object
-- @return Object metadata
function data:getObjectMetadata() : Types.ObjectMetadata
	return self:getMetadata().objectMetadata
end

-- Returns the storage for this data
-- @return The storage
function data:getStorage(changeUUIDToInstances : boolean) : {[any]:any}
	if(changeUUIDToInstances) then
		local fakeStorage = self.storage
		local realStorage = {}
		for _, uuid in fakeStorage do
			local instance = helper.getInstanceFromUUID(uuid)
			if(not instance) then continue end
			table.insert(realStorage, instance)
		end
		
		return realStorage
	end
	
	return self.storage
end

-- Returns data about this data
-- @return Metadata
function data:getMetadata() : Metadata
	return self.metadata
end

function data:getStorageIdentifier() : string
	return self:getMetadata().storageIdentifier
end

-- Get the current working version for this data. Used to compare to clients to help them determine whether they need to be synced or not
-- @return Version
function data:getVersion() : number
	return self:getMetadata().version
end

-- Increase whenever data storage is edited
function data:increaseVersion()
	self:getMetadata().version += 1
end

-- Lets you assign a function to run for when a key's value has been changed
-- @param any : What you are listening to
-- @param listener : A function to run for when the key's value changes
-- @return A StopListener which allows you to stop the listener
function data:listen(key : any, keyListener : Types.KeyListener) : Types.StopListener
	self:isRunnable()
	self:getMetadata().keyListeners[key] = self:getMetadata().keyListeners[key] or {}
	table.insert(self:getMetadata().keyListeners[key], keyListener)

	local stopper : Types.StopListener = Types.stopListener.new()
	stopper.listener = keyListener
	stopper.listenerIn = self:getMetadata().keyListeners[key]
	return stopper
end

-- Assign sanity checks to specific keys that determine if a player is allowed to see it
-- @param keys : Specified table of keys
-- @param func : The function used to test the player
-- @param allowToFuture : Whether to apply to future keys or not
function data:setKeyChecks(keys : {any}, func : PlayerAllowedWithValueCheck, allowToFuture : boolean)
	self:isRunnable()
	for _, key in keys do
		self:getMetadata().keySanityChecks[key] = self:getMetadata().keySanityChecks[key] or {}
		table.insert(self:getMetadata().keySanityChecks[key], func)
	end
	
	if(allowToFuture) then
		self:onSet(function(key : any, oldValue : any, value : any)			
			self:getMetadata().keySanityChecks[key] = self:getMetadata().keySanityChecks[key] or {}
			local tble = self:getMetadata().keySanityChecks[key]
			if(not table.find(tble, func)) then
				table.insert(tble, func)

				self:replicateValueChange(key, value)
			end
		end)
	end
end

-- Tests a sanity check for a key against a player
-- @param requestingPlayer : The player to test
-- @param key : What key to use
function data:testKeyCheck(requestingPlayer : Player, key : any)
	local keySuccess = false
	local valueSuccess = false
	
	local tble = self:getMetadata().keySanityChecks[key]
	if(tble) then
		for _, func : PlayerAllowedWithValueCheck in self:getMetadata().keySanityChecks[key] do
			local _keySuccess , _valueSuccess = func(requestingPlayer)
			if(_keySuccess) then
				keySuccess = _keySuccess
				
				if(_valueSuccess) then
					valueSuccess = _valueSuccess
				end
			end
			
			if(keySuccess and valueSuccess) then break end
		end
	end
	
	return keySuccess, valueSuccess
end

-- Lets you determine who is allowed to know this data exists: When called, this will automatically replicate to all existing players
-- @param func : A function given a Player parameter that returns whether they are allowed to see this data
function data:setAccessCheck(func : PlayerAllowed)
	self:isRunnable()

	local players = Players:GetPlayers()
	local replicatedData : Types.ReplicatedData = {
		storageIdentifier=self:getStorageIdentifier(),
		tag=self:getTag(),
		object=self:getObject(true),
		storage={},
		objectMetadata=self:getObjectMetadata()
	}

	for _, player in players do
		if(not Util.isAdmin(player)) then
			Util.fireRemote("DataRemoved", player, replicatedData)
			--DataCommunication.packets.DataRemoved.sendTo(replicatedData, player)	
		end	
	end
	
	self:getMetadata().accessSanityCheck = func

	for _, player in players do
		self:replicateIfPossibleToPlayer(player, true)
	end
end

-- Tests the given player with the data's access sanity check
-- @param requestingPlayer : The wanted player
-- @return Whether they are allowed to access this data
function data:testAccessCheck(requestingPlayer : Player)
	self:isRunnable()
	return self:getMetadata().accessSanityCheck and self:getMetadata().accessSanityCheck(requestingPlayer)
end

-- Replicates as much data to the player as allowed
-- @param player : The player wanted to replicate to
-- @param skipAdmin : Whether to not replicate to admins
function data:replicateIfPossibleToPlayer(player : Player, skipAdmin : boolean)
	if(self:testAccessCheck(player)) then
		local replicatedStorage = {}
		
		for key, value in self:getStorage() do
			local keySuccess, valueSuccess = self:testKeyCheck(player, key)
			if(keySuccess) then
				if(not valueSuccess) then
					value = "notreplicated"
				end
				replicatedStorage[key] = value
			end
		end

		local replicatedData : Types.ReplicatedData = {
			storageIdentifier=self:getStorageIdentifier(),
			tag=self:getTag(),
			object=self:getObject(true),
			storage=replicatedStorage,
			objectMetadata = self:getObjectMetadata(),
			version=self:getVersion()
		}
		--DataCommunication.packets.DataCreated.sendTo(replicatedData, player)
		Util.fireRemote("DataCreated", player, replicatedData)
	end
	
	if(Util.isAdmin(player) and not skipAdmin) then
		local replicatedStorage = {}

		for key, value in self:getStorage() do
			replicatedStorage[key] = value
		end

		local replicatedData : Types.ReplicatedData = {
			storageIdentifier="admin",
			tag=self:getTag(),
			object=self:getObject(true),
			storage=replicatedStorage,
			objectMetadata = self:getObjectMetadata(),
			version=self:getVersion()
		}
		--DataCommunication.packets.DataCreated.sendTo(replicatedData, player)
		Util.fireRemote("DataCreated", player, replicatedData)
	end
end

-- Lets you assign a function to run for when setValue is called
-- @param listener : A function to run for when setValue is called
-- @return A StopListener which allows you to stop the listener
function data:onSet(onSetListener : Types.OnSetListener) : Types.StopListener
	self:isRunnable()
	table.insert(self:getMetadata().onSetListeners, onSetListener)
	
	local stopper = Types.stopListener.new()
	stopper.listener = onSetListener
	stopper.listenerIn = self:getMetadata().onSetListeners
	
	return stopper
end

-- Stops the current data from all its activities and effectively destroys it. 
-- You must call this when you are finished using the data, whether that is removing its assigned object or being done with it! Otherwise you will cause memory leaks!!
function data:remove()
	local replicatedData : Types.ReplicatedDataRemoving = {
		tag=self:getTag(),
		object=self:getObject(true),
		objectMetadata=self:getObjectMetadata()
	}

	for _, player in Players:GetPlayers() do
		if(self:testAccessCheck(player)) then
			--DataCommunication.packets.DataRemoved.sendTo(replicatedData, player)
			Util.fireRemote("DataRemoved", player, replicatedData)
		end
	end
	
	local metadata : Metadata = self:getMetadata() :: Metadata
	metadata.active = false
	metadata.onSetListeners = nil 
	metadata.keyListeners = nil
	storages[metadata.storageIdentifier][metadata.tag][metadata.object] = nil
	
	if(not helper.getTagFromObject(metadata.object)) then -- Are there other datas that are assigned this instance? If not, we will clean up the UUID
		UUIDsToInstances[metadata.object] = nil
	end
	table.freeze(self)
	self = nil
end

export type Data = typeof(data)
export type PlayerAllowed = (Player) -> boolean
export type PlayerAllowedWithValueCheck = (Player) -> (boolean, boolean)
export type Metadata = {
	storageIdentifier : string,
	tag : string,
	object : any,
	objectMetadata : Types.ObjectMetadata,
	active : boolean,
	keyListeners : {[any]:{Types.KeyListener}},
	onSetListeners : {Types.OnSetListener},
	keySanityChecks : {[any]:{PlayerAllowedWithValueCheck}},
	accessSanityCheck : PlayerAllowed,
	version : number
}

-- Creates or gets data for an object based on given tag
-- @param tag : The tag you want
-- @param object : The object you want to create data for
-- @param waitTime : How long you should wait for existing data before creating new data for the object
-- @return New or existing data
function helper.newOrGet(tag : string, object : any, waitTime : number?, storageIdentifier : string) : Data
	Util.assert(tag and object, "No tag or object provided for data..")
	local success, data = pcall(helper.get, tag, object, waitTime, storageIdentifier)
	return (success and data) or helper.new(tag, object, storageIdentifier)
end

-- Creates data for an object based on given tag. This will error if data already exists.
-- @param tag : The tag you want
-- @param object : The object you want to create data for
-- @return Newly created data
function helper.new(tag : string, object : any, storageIdentifier : string) : Data
	Util.assert(tag and object ~= nil, "No tag or object provided for data..")
	local tagToDatas = storages[storageIdentifier] or storages.default
	tagToDatas[tag] = tagToDatas[tag] or {}
	local list = tagToDatas[tag]
	local existingData = list[object]
	Util.assert(not existingData, `Data already exists for given tag and object: {tag}, {object}`)
	
	local data : Data = Util.deepClone(data)
	
	local isInstance = typeof(object)=="Instance"
	
	data.storage = {}
	local metadata : Metadata = {
		storageIdentifier=storageIdentifier or "default",
		tag=tag,
		object=(isInstance and helper.generateOrGetExistingUUID(object)) or object,
		objectMetadata={
			isInstance=isInstance
		},
		active=false,
		keyListeners = {},
		onSetListeners = {},
		keySanityChecks = {},
		accessSanityCheck = function(player : Player) return false end,
		version=1
	}
	
	data.metadata = metadata
	metadata.active = true
	list[metadata.object] = data
	
	for _, player in Players:GetPlayers() do
		-- for admins
		data:replicateIfPossibleToPlayer(player)
	end
	
	return data
end

-- Gets data for an object based on given tag
-- @param tag : The tag you want
-- @param object : The object you want to create data for
-- @param waitTime : How long you should wait if the data could not be found on first attempt
-- @return Existing data
function helper.get(tag : any, object : any , waitTime : number?, storageIdentifier : string) : Data
	Util.assert(tag and object, "No tag or object provided for data..")
	local tagToDatas = storages[storageIdentifier] or storages.default
	tagToDatas[tag] = tagToDatas[tag] or {}
	local list = tagToDatas[tag]
	if(typeof(object)=='Instance') then
		object = helper.getUUIDFromInstance(object)
		if(not object) then return end
	end
	local dataToReturn = list[object]
	if(not dataToReturn and waitTime) then
		local startTime = os.clock()
		repeat
			task.wait()
			dataToReturn = list[object]
		until dataToReturn or os.clock() - startTime > waitTime
		if(not dataToReturn) then warn(`Could not find data for {object} with tag, {tag}, in amount of seconds: {waitTime}`) end
	end
	return dataToReturn
end

-- Get the objects assigned this tag
-- @param tag : The tag you want
function helper.getObjectsWithTag(tag : any, storageIdentifier : string)
	local tagToDatas = storages[storageIdentifier] or storages.default
	local objects = {}
	for _tag, objectsToData in tagToDatas do
		if(tag == _tag) then  
			for object, _ in objectsToData do
				table.insert(objects, object)
			end
		end
	end
	return objects
end

-- Whether this object has the given tag
-- @param tag : The tag you want
-- @param object : The object given
function helper.objectHasTag(tag : any, object : any, storageIdentifier : string)
	local tagToDatas = storages[storageIdentifier] or storages.default
	tagToDatas[tag] = tagToDatas[tag] or {}
	return tagToDatas[tag][object] ~= nil
end

-- Returns the first tag found for this object
-- @param object : The object given
function helper.getTagFromObject(object : any, storageIdentifier : string) : string?
	local tagToDatas = storages[storageIdentifier] or storages.default
	for tag, objectsToData in tagToDatas do
		if(objectsToData[object]) then return tag end
	end
	return nil
end

-- Returns all datas
-- @return All datas
function helper.getAllDatas(storageIdentifier : string) : {Data}
	local tagToDatas = storages[storageIdentifier] or storages.default
	local datas = {}
	for _, objectsToData in tagToDatas do
		for _, data in objectsToData do
			table.insert(datas, data)
		end
	end
	return datas
end

-- Returns all objects
-- @return All objects
function helper.getAllObjects(storageIdentifier : string)
	local tagToDatas = storages[storageIdentifier] or storages.default
	local objects = {}
	for _, objectsToData in tagToDatas do
		for object, _ in objectsToData do
			table.insert(objects, object)
		end
	end
	return objects
end

-- Returns tags to objects to datas
-- @return Tags to objects to datas
function helper.getStorage(storageIdentifier : string)
	local tagToDatas = storages[storageIdentifier] or storages.default
	return tagToDatas
end

-- Returns all created storages
-- @return Storages that hold tagToDatas
function helper.getAllStorages()
	return storages
end

-- Gets an instance from its UUID
-- @param uuid : The UUID given
-- @return An instance assigned to the UUID if there is one
function helper.getInstanceFromUUID(uuid : string) : Instance?
	return UUIDsToInstances[uuid]
end

-- Get a UUID from its instance
-- @param instance : The instance given
-- @return A UUID if the instance has one
function helper.getUUIDFromInstance(instance : Instance) : string?
	for uuid, _instance in UUIDsToInstances do
		if(_instance == instance) then return uuid end
	end
	return nil
end

-- Generates a UUID or gets an existing one for a specified instance
-- @param instance : The instance given
-- @return A UUID assigned to the instance
function helper.generateOrGetExistingUUID(instance : Instance)
	local uuid = helper.getUUIDFromInstance(instance)
	if(not uuid) then
		repeat
			uuid = HttpService:GenerateGUID(false)
		until not UUIDsToInstances[uuid]
		UUIDsToInstances[uuid]=instance
	end
	return uuid
end

-- Determines whether the given string is a UUID or not
-- @param uuid : The string to test
-- @return Whether the string is a valid UUID or not
function helper.isValidUUID(uuid : string)
	if(typeof(uuid) ~= 'string') then return end
	
	local split = uuid:split("-")
	return #split == 5 and #uuid == 36
end

Util.onInvoke("GetUUIDFromInstance", function(player : Player, instance : Instance | {Instance})
--DataCommunication.queries.GetUUIDFromInstance.listen(function(instance : Instance, player : Player)
	if(typeof(instance) == 'table') then
		local uuids = {}
		for index, _instance in instance do
			local uuid = helper.getUUIDFromInstance(_instance)
			if(uuid) then
				uuids[uuid] = _instance
			end
		end
		return uuids
	else
		return helper.getUUIDFromInstance(instance)
	end
end)

Util.onInvoke("GetInstanceFromUUID", function(player : Player, uuid : string | {string})
--DataCommunication.queries.GetInstanceFromUUID.listen(function(uuid : string, player : Player)
	if(typeof(uuid) == 'table') then
		local instances = {}
		for _, _uuid in uuid do
			local instance = helper.getInstanceFromUUID(_uuid)
			if(instance) then
				instances[_uuid] = instance
			end
		end
		return instances
	else
		return helper.getInstanceFromUUID(uuid)
	end
end)

Util.onRemote("QuickReplicateAll", function(player: Player) 
--DataCommunication.packets.QuickReplicateAll.listen(function(_, player : Player)
	local datas = helper.getAllDatas()
	for _, data in datas do
		data:replicateIfPossibleToPlayer(player)
	end
end)

Util.onRemote("ValueEdited", function(player: Player, valueEdited : Types.ValueEdited) 
--DataCommunication.packets.ValueEdited.listen(function(valueEdited : Types.ValueEdited, player : Player)
	if(Util.isAdmin(player)) then
		local data = helper.get(valueEdited.tag, valueEdited.object, nil)
		if(data and valueEdited.key) then
			data:setValue(valueEdited.key, valueEdited.value)
		end
	end
end)

return helper
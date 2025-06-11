--!strict
----------------------
-- Name: ClientDataCreator
-- Authors: MianReplicate
-- Created: 1/2/2025
-- Purpose: To handle and replicate known data about objects in a simple way: This is a direct port of the server-sided version with some edits for the client
----------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
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
	default = {},
	admin = {}
}

local UUIDsToInstances : {[string]:Instance} | {} = {}

local currentlyFullReplicating = false

function data:isRunnable()
	Util.assert(self.metadata.active, `Cannot run functions on inactive data for object! {self.metadata.object}`)
end

-- Activate listeners for when a value has changed, typically you will not need to run this manually
-- @param key : What the value should be assigned to
-- @param oldValue : What the old value was
-- @param value : What the new value is
function data:valueChanged(key : any, oldValue : any?, value : any)
	self:isRunnable()
	key = helper.getInstanceFromUUID(key, true) or key
	
	if oldValue then
		oldValue = helper.getInstanceFromUUID(oldValue, true) or oldValue
	end
	if value then
		value = helper.getInstanceFromUUID(value, true) or value
	end
	
	local keyListeners = self:getMetadata().keyListeners[key]
	if keyListeners then
		for _, listener in keyListeners do
			listener(oldValue, value)
		end
	end

	for _, onSetListener in self:getMetadata().onSetListeners do
		onSetListener(key, oldValue, value)
	end
end

-- Assign a value to a key within the data
-- @param key : What the value should be assigned to
-- @param value : What you want to put within the data
function data:setValue(key : any, value : any)
	self:isRunnable()
	if key and typeof(key) == 'Instance' then
		key = helper.generateOrGetExistingUUID(key)
	end

	if value and typeof(value) == 'Instance' then
		value = helper.generateOrGetExistingUUID(value)
	end
	local oldValue = self.storage[key]
	self.storage[key] = value
	task.spawn(self.valueChanged, self, key, oldValue, value)
end

-- Returns a value given a key.  If the value is a UUID, then it will return the instance assigned with the UUID
-- @param key : What the value is assigned to
-- @return The value assigned to the key
function data:getValue(key : any) : any?
	self:isRunnable()
	key = helper.getUUIDFromInstance(key, true) or key
	local value : any = self.storage[key]
	local toReturn = (value and helper.getInstanceFromUUID(value, true)) or value
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
-- @return The object
function data:getObject()
	local object = self:getMetadata().object
	local toReturn = (object and helper.getInstanceFromUUID(object, true)) or object
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

-- Get the current version for this data. This is synced with the server's version. The point of this is to determine whether the client's data is outdated.
-- @return Version
function data:getVersion() : number
	return self:getMetadata().version
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
export type Metadata = {
	storageIdentifier : string,
	tag : string,
	object : any,
	objectMetadata : Types.ObjectMetadata,
	active : boolean,
	keyListeners : {[any]:{Types.KeyListener}},
	onSetListeners : {Types.OnSetListener},
	version : number
}

-- Creates new data or overrides data from given replicated data. You usually do not need to run this manually
-- @param replicatedData : The replicated data given from the server
-- @return Data created from replicated data
function helper.fromReplicatedData(replicatedData : Types.ReplicatedData)
	local tag = replicatedData.tag
	local object = replicatedData.object
	local storageIdentifier = replicatedData.storageIdentifier
	
	local exists = helper.get(tag, object, nil, storageIdentifier)
	if(exists) then
		if(replicatedData.version ~= exists:getVersion()) then
			warn(`Server tried to give us replicated data for an object that already exists: ValueChanged should be used instead! Tag: {tag} | Object: {object}`)
			exists:getMetadata().version = replicatedData.version
			for key, value in replicatedData.storage do
				exists:setValue(key, value)
			end
		end
		return exists
	end
	
	local tagToDatas = storages[storageIdentifier]
	if(not tagToDatas) then
		storageIdentifier = 'default'
		tagToDatas = storages[storageIdentifier]
	end
	
	tagToDatas[tag] = tagToDatas[tag] or {}
	local list = tagToDatas[tag]
	
	local newData : Data = {} :: Data

	for key, value in data do
		newData[key] = value
	end
	
	local objectMetadata = replicatedData.objectMetadata

	newData.storage = replicatedData.storage
	local metadata : Metadata = {
		storageIdentifier=storageIdentifier,
		tag=tag,
		object=object,
		objectMetadata=objectMetadata,
		active=false,
		keyListeners = {},
		onSetListeners = {},
		version=replicatedData.version
	}
	newData.metadata = metadata
	metadata.active = true
	list[metadata.object] = newData
	
	return newData
end

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
		version=1
	}
	data.metadata = metadata
	metadata.active = true
	list[metadata.object] = data

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
		object = helper.getUUIDFromInstance(object, true) or object
	end
	local dataToReturn = list[object]
	if(not dataToReturn and waitTime) then
		local startTime = os.clock()
		repeat
			task.wait()
			if(typeof(object)=='Instance') then
				object = helper.getUUIDFromInstance(object, true) or object
			end
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
function helper.getInstanceFromUUID(uuid : string, yield : boolean?)
	if(not helper.isValidUUID(uuid)) then return nil end
	
	local instance = UUIDsToInstances[uuid]
	if(not instance and yield) then
		instance = Util.invokeRemote("GetInstanceFromUUID", uuid)
		if(instance) then
			UUIDsToInstances[uuid] = instance
		end
	end
	return instance
end

-- Get a UUID from its instance
-- @param instance : The instance given
-- @return A UUID if the instance has one
function helper.getUUIDFromInstance(instance : Instance, yield : boolean?) : string?
	if(typeof(instance) ~= "Instance") then return nil end
	local uuid = nil
	for _uuid, _instance in UUIDsToInstances do
		if(_instance == instance) then uuid = _uuid break end
	end
	
	if(yield) then
		local uuid = Util.invokeRemote("GetUUIDFromInstance", instance)
		if(uuid) then
			UUIDsToInstances[uuid] = instance
		end
	end
	return uuid
end

-- Generates a UUID or gets an existing one for a specified instance
-- @param instance : The instance given
-- @return A UUID assigned to the instance
function helper.generateOrGetExistingUUID(instance : Instance)
	local uuid = helper.getUUIDFromInstance(instance, false)
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

-- Should be run when the module is first initiated. This ensures that we have all latest data on join
function helper.quickReplicate()
	currentlyFullReplicating = true
	for string, storage in storages do
		storages[string] = {} -- reset
	end
	
	Util.fireRemote("QuickReplicateAll")
	--DataCommunication.packets.QuickReplicateAll.send()
	task.wait(1)
	currentlyFullReplicating = false
end

Util.onRemote("DataCreated", helper.fromReplicatedData)
--DataCommunication.packets.DataCreated.listen(helper.fromReplicatedData)

Util.onRemote("DataRemoved", function(replicatedData : Types.ReplicatedDataRemoving)
--DataCommunication.packets.DataRemoved.listen(function(replicatedData : Types.ReplicatedDataRemoving)
	local data : Data = helper.get(replicatedData.tag, replicatedData.object, nil, replicatedData.storageIdentifier)
	if(data) then
		data:remove()
	end
end)

Util.onRemote("ValueChanged", function(valueChanged : Types.ValueChanged)
--DataCommunication.packets.ValueChanged.listen(function(valueChanged : Types.ValueChanged)
	if(not valueChanged.tag or not valueChanged.object) then return nil end
	local data = helper.get(valueChanged.tag, valueChanged.object, nil, valueChanged.storageIdentifier)
	if(currentlyFullReplicating and not data) then return end
	local key, value = valueChanged.key, valueChanged.value
	if(data) then
		-- Only update if the version number isn't the same, this is to avoid repetitive listener runs
		if(valueChanged.version ~= data:getVersion()) then
			data:getMetadata().version = valueChanged.version
			data:setValue(key, value)
		end
	else
		warn(`Missing data: replicating all to fix issue`)
		warn(valueChanged)
		helper.quickReplicate() -- Something is terribly wrong if we are missing data..?
	end
end)

helper.quickReplicate()

local instances = {}
local timeToReplicate = nil

local function addToPending(instance : Instance)
	if(helper.getUUIDFromInstance(instance)) then return end
	table.insert(instances, instance)

	timeToReplicate = os.clock()
end

local function getUUIDsFromInstances(instances : {Instance})
	local uuids = Util.invokeRemote("GetUUIDFromInstance", instances)
	for uuid, instance in uuids do
		UUIDsToInstances[uuid] = instance
	end
end

getUUIDsFromInstances(workspace:GetDescendants())

workspace.DescendantAdded:Connect(addToPending)

RunService.Heartbeat:Connect(function()
	if(timeToReplicate) then
		if(os.clock() - timeToReplicate > 0.05) then
			if(#instances > 0) then
				local clone = table.clone(instances)
				instances = {}
				getUUIDsFromInstances(clone)
			end
			timeToReplicate = nil
		end
	end
end)

return helper
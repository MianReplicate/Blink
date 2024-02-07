----------------------
-- Name: HierachyValueSaving
-- Author: LoxiGoose
-- Created: 11/19/2023
-- Last Updated: 11/24/2023
----------------------

--[[
This module uses ProfileService for automated saving. 
The main function of this module is reading the data and converting them into actual instances/folders for the player that can be changed/listened

Dynamic Data:
Any instances that are not part of the regular datatemplate can be saved if under a folder that is in the datatemplate.
When these instances are created, you MUST run the writeInstanceOnChange function for them to properly be saved!

Duplicate Instances:
Instances with the same name as each other WILL not be saved correctly! It will cause massive issues with your data so just don't.

(I'm serious, if you have two instances with the same name as each other, only one of them will save.)
]]

local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ProfileService = ServerScriptService:FindFirstChild("ProfileService", true) or script.Parent:FindFirstChild("ProfileService", true)

if not ProfileService then
	error("ProfileService not detected anywhere!")
else
	ProfileService = require(ProfileService)
end

local profiles = {}
local debugMode = script:GetAttribute("Debug")
local setup = false

function retrieveParentsOfInstance(instance : Instance, instanceMain : Instance)
	local parents = {}
	local parent = instance
	repeat
		parent = parent.Parent
		if parent ~= instanceMain and parent ~= nil then
			table.insert(parents, parent.Name)
		end
	until parent == instanceMain or parent == nil
	return parents
end

function getIndexWhereInstanceIsInProfile(instance : Instance, instanceMain : Instance, profile, optionalParents)
	local parents = optionalParents or retrieveParentsOfInstance(instance, instanceMain)
	local parent

	local parentInData = profile.Data
	if #parents > 0 then
		for i = #parents, 1, -1 do
			parent = parents[i]
			if typeof(parentInData[parent]) ~= 'table' or parentInData[parent].children == nil then
				parentInData[parent] = convertInstanceIntoData(instance)
			end
			parentInData = parentInData[parent].children
		end
	elseif typeof(parentInData[instance.Name]) ~= 'table' or parentInData[instance.Name].children == nil then
		parentInData[instance.Name] = convertInstanceIntoData(instance)
	end

	return parentInData, parents
end

function convertInstanceIntoData(instance : Instance)
	local properties = {
		-- Value = ?,
		Attributes = {}
	}
	if instance:IsA("ValueBase") then
		properties.Value = instance.Value
	end
	properties.Attributes = instance:GetAttributes()

	local instanceChildren = instance:GetChildren()
	local children = {}

	for index, childInstance in instanceChildren do
		children[childInstance.Name] = convertInstanceIntoData(childInstance)
	end

	return {
		properties = properties,
		children = children
	}
end

function writeInstanceIntoData(parent, instance)
	parent[instance.Name] = convertInstanceIntoData(instance)
	return true
end

function debugMessage(stringMessage, ...)
	if debugMode then
		print(stringMessage, ...)
	end
end

function module.getProfiles()
	return profiles
end

function module.retrieveInstanceProfileData(instanceProfile : Instance)
	local profileData = profiles[instanceProfile]

	if not profileData then error("ProfileData for "..instanceProfile.Name.." is missing!") return nil end
	
	return profileData
end
--[[
Can be used for removing old data or dynamic data that is no longer used. This will also destroy the value itself.
Any data from the default template that is removed will be readded when loading the profile
]]
function module.removeInstanceFromData(instanceMain : Instance, instance : Instance, optionalParents)
	local profileData = module.retrieveInstanceProfileData(instanceMain)
	local profile = profileData[1]
	
	local parentInData = getIndexWhereInstanceIsInProfile(instance, instanceMain, profile, optionalParents)
	local name = instance.Name
	if parentInData[name] == nil then
		return -- Already removed
	end
	instance:Destroy() -- Destroy before setting to nil that way any watchers waiting for this value to change are removed
	parentInData[name] = nil
	
	debugMessage("Removed "..instance.Name.." from "..instanceMain.Name.."'s profile!")
	return true
end

--[[
This should be used on new values that are created that you want to write to the player's profile!
This runs automatically for new children under the instance that is watched by this function
]]
function module.writeInstanceOnChange(instanceMain : Instance, instance : Instance)
	local profileData = module.retrieveInstanceProfileData(instanceMain)
	local profile = profileData[1]
	local parentInData, parents = getIndexWhereInstanceIsInProfile(instance, instanceMain, profile)
	
	local connections = {}

	local function disconnectConnections()
		for _, connection : RBXScriptConnection in connections do
			connection:Disconnect()
		end
	end
	
	table.insert(connections, instance.Changed:Connect(function(property)
		if property == "Parent" then
			 return
		end

		if profile:IsActive() then
			parentInData, parents = getIndexWhereInstanceIsInProfile(instance, instanceMain, profile)

			writeInstanceIntoData(parentInData, instance)
			debugMessage("Successfully wrote "..instance.Name.." to "..instanceMain.Name.."'s profile!")
			debugMessage(parents)
		else
			warn("Profile is no longer active! Can't save the new value of "..instance.Name)
			disconnectConnections()
		end
	end))
	
	table.insert(connections, instance.AttributeChanged:Connect(function()
		if profile:IsActive() then
			parentInData, parents = getIndexWhereInstanceIsInProfile(instance, instanceMain, profile)
			
			writeInstanceIntoData(parentInData, instance)
			debugMessage("Successfully wrote "..instance.Name.." to "..instanceMain.Name.."'s profile!")
			debugMessage(parents)
		else
			warn("Profile is no longer active! Can't save the new value of "..instance.Name)
			disconnectConnections()
		end
	end))
	
	table.insert(connections, instance.AncestryChanged:Connect(function()
		if instanceMain.Parent == nil then
			return
		elseif not instance:IsDescendantOf(instanceMain) and instanceMain.Parent ~= nil then
			module.removeInstanceFromData(instanceMain, instance, parents)
			return
		end
		
		if profile:IsActive() then
			parentInData, parents = getIndexWhereInstanceIsInProfile(instance, instanceMain, profile, parents)
			
			if parentInData then
				parentInData[instance.Name] = nil
			end
			
			parentInData, parents = getIndexWhereInstanceIsInProfile(instance, instanceMain, profile)
			writeInstanceIntoData(parentInData, instance)
		else
			warn("Profile is no longer active! Can't write the new value added under "..instance.Name)
		end
	end))
	
	writeInstanceIntoData(parentInData, instance)
	
	debugMessage("Listening to "..instance.Name.." for any changes..", instanceMain)
	return true
end

function readData(instanceMain : Instance, profile)
	local data = profile.Data

	local typesofInitialization
	local function crawl(index, saveableDataInstance, parent)
		
		debugMessage("Reading "..index)
		
		local valueInstance
		
		if typeof(saveableDataInstance) == "table" and saveableDataInstance.properties then
			local data = saveableDataInstance.properties
			local children = saveableDataInstance.children
			local value = data.Value or {} -- If the value is nil, then assume it's just a folder
			valueInstance = typesofInitialization[typeof(value)](value)
			
			valueInstance.Name = index
			valueInstance.Parent = parent

			for attributestring, attribute in data.Attributes do
				debugMessage("Setting attribute "..attributestring.." for "..index)
				valueInstance:SetAttribute(attributestring, attribute)
			end
			
			debugMessage("Crawling through children for "..index)
			for name, _saveableDataInstance in children do
				crawl(name, _saveableDataInstance, valueInstance)
			end
		else
			valueInstance = typesofInitialization[typeof(saveableDataInstance)](saveableDataInstance)
			
			valueInstance.Name = index
			valueInstance.Parent = parent
		end

		module.writeInstanceOnChange(instanceMain, valueInstance)
	end
	
	typesofInitialization = {
		["table"] = function(value)
			local typeofValue = Instance.new("Folder")
			return typeofValue
		end,
		number = function(value)
			local typeofValue = Instance.new("NumberValue")
			typeofValue.Value = value
			return typeofValue
		end,
		boolean = function(value)
			local typeofValue = Instance.new("BoolValue")
			typeofValue.Value = value
			return typeofValue
		end,
		["string"] = function(value)
			local typeofValue = Instance.new("StringValue")
			typeofValue.Value = value
			return typeofValue
		end,
	}

	for name, saveableDataInstance in data do
		crawl(name, saveableDataInstance, instanceMain)
	end
	return true
end

function rewriteDataInCorrectFormat(data)
	
	local function crawl(name, dataValue, parent)
		local isTable = typeof(dataValue) == 'table'
		
		local data = {
			children = {},
			properties = {
				Attributes = {},
			}
		}
		
		if not isTable then
			data.properties.Value = dataValue
		else
			if dataValue.children and dataValue.properties then
				return
			end
			
			for name, dataValue in dataValue do
				crawl(name, dataValue, data.children)
			end
		end
		
		parent[name] = data
	end
	
	for name, dataValue in data do
		crawl(name, dataValue, data)
	end
	
	return data
end

function module.start(defaultData, dataStoreName)
	if setup then error("PlayerDataHelper is already setup!") return end
	setup = true
	
	defaultData = rewriteDataInCorrectFormat(defaultData)
	local profileStore = ProfileService.GetProfileStore(dataStoreName or "PlayerData", defaultData)
	
	local function PlayerAdded(player)
		local profile = profileStore:LoadProfileAsync("Player_" .. player.UserId)
		if profile ~= nil then
			if profiles[player] ~= nil then
				error("Already used PlayerAdded function on "..player.Name)
			end
			
			profile:AddUserId(player.UserId) -- GDPR compliance
			profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
			profile:ListenToRelease(function()
				profiles[player] = nil
				-- The profile could've been loaded on another Roblox server:
				player:Kick("Data is loaded on another server, please try rejoining.")
			end)
			if player:IsDescendantOf(Players) == true then
				profiles[player] = {profile, false}
				-- A profile has been successfully loaded:
				print("Successfully loaded "..player.Name.."'s data.")
				readData(player, profile)
				print("Successfully read "..player.Name.."'s data.")
				profiles[player] = {profile, true}
			else
				-- Player left before the profile loaded:
				profile:Release()
			end
		else
			-- The profile couldn't be loaded possibly due to other
			--   Roblox servers trying to load this profile at the same time:
			player:Kick("We aren't able to load your data at the moment, please try again another time.")
		end
	end
	
	Players.PlayerAdded:Connect(PlayerAdded)
	
	Players.PlayerRemoving:Connect(function(player : Player)
		local profileData = profiles[player]
		if profileData ~= nil and profileData[1] then
			profileData[1]:Release()
		end
	end)
	
	-- Account for any players that joined before the PlayerAdded event
	for _, player in Players:GetPlayers() do
		PlayerAdded(player)
	end
end

return module
----------------------
-- Name: GameLibrary
-- Authors: LoxiGoose, Zetalasis
-- Created: 11/12/2023
-- Last Updated: 2/5/2024
----------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Utils = require(Modules:WaitForChild("Utils"))
local roleData = require(script:WaitForChild("RoleData"))

local activeRoleDatas = {}
local gameLibrary = {}

workspace.DescendantRemoving:Connect(function(characterModel : Model)
	if characterModel:FindFirstChild("Humanoid") then
		if gameLibrary.getRoleData(characterModel) then -- Might've already been handled by another removal
			gameLibrary.removeRoleCharacter(characterModel)
		end
	end
end)

-- Category: Roles

--[[
Creates a role character for the specified role

Params:
characterModel = The model you want
roleType = The role you want to make
]]
function gameLibrary.createRoleCharacter(characterModel : Model, roleType : string)
	local roleData = setmetatable({}, roleData)
	characterModel.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	characterModel.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	characterModel.Humanoid.JumpPower = 0
	
	characterModel.Parent = workspace -- If not already in workspace
	roleData:init(characterModel, roleType)
	activeRoleDatas[characterModel] = roleData
	
	if roleType == "Weeping Angel" then
		Utils.FireBindable("OnRoleAdded", "Angel", characterModel)
	elseif roleType == "Survivor" then
		Utils.FireBindable("OnRoleAdded", "Angel", characterModel)
	end
	
	return roleData
end

--[[
Removes a role character for the specified model

Params:
characterModel = The model you want
]]
function gameLibrary.removeRoleCharacter(characterModel : Model)
	local roleData = gameLibrary.getRoleData(characterModel)
	if roleData then
		activeRoleDatas[characterModel] = nil
		roleData:setData("inactive", true)
	else
		warn("RoleData already doesn't exist for", characterModel)
	end
end

--[[
Turns a player into a role character with a specified role

Params:
player = The player that you want to transform
characterModel (optional) = The character model you want to use, if null then the player model is used
position (optional) = The position you want the player to be placed, if null then the player position is used
roleType = The role you want the player to be
]]
function gameLibrary.transformPlayerIntoRole(player : Player, characterModel : Model, position : Vector3, roleType : string)
	local position = position or player.Character.HumanoidRootPart.Position
	if characterModel then
		characterModel = characterModel:Clone()
	else
		characterModel = Players:CreateHumanoidModelFromUserId(player.UserId)
	end
	
	characterModel.HumanoidRootPart.CFrame = CFrame.new(position)
	characterModel.Name = player.Name
	
	local roleData = gameLibrary.createRoleCharacter(characterModel, roleType)
	roleData:setData("player", player)
	
	player.Character = characterModel
	roleData:sendInfoToClient(roleType)
	return roleData
end

--[[
Returns all role datas with the specified type

Params:
roleDataType: The role data type
]]
function gameLibrary.getAllSpecifiedRoleDatas(roleDataType : string)
	local roleDatas = {}
	
	for character, roleData in activeRoleDatas do
		if roleData:getData("type") == roleDataType then
			roleDatas[character] = roleData
		end
	end
	
	return roleDatas
end

--[[
Returns the roleData for the requested character if it exists

Params:
character = The character that you wish to get a metatable from
]]
function gameLibrary.getRoleData(character : Model)
	return activeRoleDatas[character]
end

-- Category: Player Setup

--[[
Sets up newly joined players

Params:
player = The player that you want to set up
]]
function gameLibrary.setupPlayer(player : Player)
	-- TODO: This will have data and stuff
end

-- Category: Lights

--[[
TODO:
1. Character Light Detection (Check when a Character is in a light)
2. Flickering
3. Dimmed Value (When the light is dimmed. Will be true if they are also off)
4. Nearby Value (How far Angels can flicker lights)
5. Work in mind with tools
]]
function gameLibrary.isObjectVisible(object : Instance, player : Instance)
	return false -- TODO: Code this once we get flashlights 'n stuff
end

-- Category: Maps
local spawnedMaps = {} -- Realistically the length of this shall never be larger than 1 - but we will still use a for pairs loop to allow for more then 1 map :shruggie:
local currentMap = nil

local ServerStorage = game:GetService("ServerStorage")
local AllMaps = ServerStorage:FindFirstChild("Maps")
local SpawnPoint = workspace:FindFirstChild("MapSpawnPoint")

function gameLibrary.loadMap(random : boolean, name : string)
	gameLibrary.deleteMaps()	
	
	if AllMaps == nil then 
		error("Maps folder missing! [game.ServerStorage.Maps] is where it is supposed to be!") 
		return -1 
	end
	
	local RandMap
	
	if (random) then
		RandMap = AllMaps:GetChildren()[math.random(1, #AllMaps:GetChildren())]
	elseif name ~= nil and random == false then
		RandMap = AllMaps:FindFirstChild(name)
	end
	
	if RandMap == nil then 
		error("Map selected was null - oops?") 
		return -1 
	end
	
	local MapClone = RandMap:Clone()
	local CFrame_, Size = MapClone:GetBoundingBox()
	local BoundingBox = Instance.new("Part")
	BoundingBox.Anchored = true
	BoundingBox.Size = Size
	BoundingBox.CFrame = CFrame_
	BoundingBox.Parent = MapClone
	
	MapClone.PrimaryPart = BoundingBox
	
	MapClone:PivotTo(SpawnPoint.CFrame)
	BoundingBox:Destroy()
	MapClone.Parent = workspace
	
	table.insert(spawnedMaps, MapClone)
	
	currentMap = MapClone
end

function gameLibrary.deleteMaps()
	for index, Map in spawnedMaps do
		if Map ~= nil then
			Map:Destroy()
		end
		
		table.remove(spawnedMaps, index)
	end
	
	currentMap = nil
end

-- Returns name
-- TODO: Add more data to mess around with!!
function gameLibrary.getMapData(map : Instance)
	if map ~= nil then
		local MapData = map:FindFirstChild("MapData")
		if MapData == nil then warn("Error: MapData not found in map "..map.Name) return -1 end
		
		local _DATA = {}
		
		local Name = MapData:FindFirstChild("MapName").Value
		
		_DATA["Name"] = Name
		
		return _DATA
	end
end

return gameLibrary
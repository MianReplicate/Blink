----------------------
-- Name: GameLibrary
-- Authors: MianReplicate, Zetalasis
-- Created: 11/12/2023
----------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local RoleStorage = game:GetService("ServerStorage"):WaitForChild("RoleStorage")

local DataRegistry = require(script.DataRegistry)
DataRegistry.registerTypes()

local RolesType = DataRegistry.getType(shared.Utils.retrieveEnum("DataTypes.Roles"))
local PlayersType = DataRegistry.getType(shared.Utils.retrieveEnum("DataTypes.Players"))

local replicatedRoles = shared.WalletCache.createNamespace("Roles", true, false, {
	[shared.Utils.retrieveEnum("SubTypes.Survivor")] = {},
	[shared.Utils.retrieveEnum("SubTypes.Angel")] = {}
})
local gameLibrary = {}

workspace.DescendantRemoving:Connect(function(characterModel : Model)
	if characterModel:FindFirstChild("Humanoid") then
		if RolesType:getDataIncludingInactive(characterModel) then
			gameLibrary.removeRoleCharacter(characterModel)
		end
	end
end)

-- Category: Roles

-- Creates a character assigned to a role. If you want to transform a player into a role character, see the other function "transformPlayerIntoRole"
-- @param The character model wanted to be used
-- @param The subtype role to assign to this character. See Roles module for the role types
-- @return The created roleData
function gameLibrary.createRoleCharacter(characterModel : Model, roleType : string)
	if characterModel:FindFirstChild("Humanoid") ~= nil then
		characterModel.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		characterModel.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		characterModel.Humanoid.JumpPower = 0
		characterModel.Humanoid.BreakJointsOnDeath = false
		characterModel.Archivable = true

		characterModel.Parent = workspace -- If not already in workspace
		local roleData = RolesType:createData(characterModel, roleType)
		replicatedRoles.addValue(characterModel, {roleType})
		shared.Utils.FireBindable("OnRoleAdded", roleType, characterModel)

		return roleData
	end
end

-- Removes a role character
-- @param The character model to remove
function gameLibrary.removeRoleCharacter(characterModel : Model)
	local role = RolesType:getDataIncludingInactive(characterModel)
	assert(role, `{characterModel} does not have a role to remove!`)
	RolesType:removeDataIfExists(characterModel)
	replicatedRoles.removeValue(characterModel, {role.subtype}) -- needs to be fixed
	local player = Players:GetPlayerFromCharacter(characterModel)
	if player then
		DataRegistry.sendCustomPacket({player}, shared.Utils.retrieveEnum("DataTypes.Roles"), nil, shared.Utils.retrieveEnum("PacketTypes.RoleRemoved"))
	end
end

-- Transforms a player into a role character
-- @param The player wanted to transform
-- @param The rig type wanted to be used. See Utils module for the rig type enums (optional)
-- @param The subtype role to assign to this player. See Roles module for the subtypes
-- @return The created roleData
function gameLibrary.transformPlayerIntoRole(player : Player, rigType : string, position : Vector3, roleType : string)
	local position = position or player.Character.HumanoidRootPart.Position
	
	local Rig
	
	if rigType then
		Rig = RoleStorage:WaitForChild(rigType):WaitForChild(roleType.."Dummy"):Clone()
	elseif not Rig then
		Rig = RoleStorage:WaitForChild(shared.Utils.retrieveEnum("RigTypes.R15")):WaitForChild(roleType.."Dummy"):Clone()
	end

	Rig.HumanoidRootPart.CFrame = CFrame.new(position)
	Rig.Name = player.Name

	local roleData = gameLibrary.createRoleCharacter(Rig, roleType)
	roleData:setValue("player", player) -- custom value that we use, not involved with data module
	roleData:addRequestableFunctionsFor(
		"ClientRunnables",
		{player},
		"keepEyesOpen", 
		"blink"
	)
	roleData:addRequestableIndexesFor(
		"ClientStats",
		{player},
		false,
		{"blinkMeter", "maxValue"},
		{"blinkDrainTime", "value"}
	)

	player.Character = Rig
	local Desc : HumanoidDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)
	if Desc.Head ~= 0 then
		Desc.Head = 0
	end
	local Anims = {"Climb", "Fall", "Idle", "Jump", "Run", "Swim", "Walk"}
	for _, s in Anims do
		Desc[s.."Animation"] = 0
	end
	Rig:WaitForChild("Humanoid"):ApplyDescription(Desc)
	Rig:WaitForChild("Animate").Enabled = true
	roleData:sendPacket({player}, shared.Utils.retrieveEnum("PacketTypes.RoleChanged"), roleType)
	return roleData
end

-- Returns all role datas with the specified subtype
-- @param The subtype role to get all datas for. See Roles module for the subtypes
-- @return A table of specified role datas
function gameLibrary.getAllSpecifiedRoleDatas(roleType : string)
	return replicatedRoles.getValues({roleType})
end

-- Returns the roleData for the requested character if it exists
-- @param The character you want to get the roleData from
-- @return The role data that is being returned
function gameLibrary.getRoleData(character : Model)
	local data = RolesType:getData(character)
	if not data then
		warn(`{character.Name} does not have any role data! (This can probably be ignored)`)
	else
		return data
	end
end

-- Returns all role datas
-- @return A table of all role datas
function gameLibrary.getRoleDatas()
	return RolesType:getDatas()
end

-- Category: Player Setup

-- Used when a player joins the server
-- @param The player to set up
-- @return The player's data
function gameLibrary.onPlayerAdded(player : Player)
	local playerData = PlayersType:createData(player, shared.Utils.retrieveEnum("SubTypes.Common"))
	return playerData
end

-- Used when a player leaves the server
-- @return The player to remove data from
function gameLibrary.onPlayerRemoved(player : Player)
	PlayersType:removeDataIfExists(player)
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
-- @param The map to get data from
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

shared.GameLibrary = gameLibrary
shared.DataRegistry = DataRegistry
return gameLibrary
----------------------
-- Name: Utils
-- Author: MianReplicate
-- Created: 11/12/2023
-- Last Updated: 12/3/2023
----------------------

local utils = {}
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Players = game:GetService("Players")
local Player = game:GetService("Players").LocalPlayer

shared.debug = function(... : any)
	if script:GetAttribute("Debug") or RunService:IsStudio() then
		print(...)
	end
end

local Constants = {
	SubTypes = {
		
	},
	DataTypes = {
	},
	PacketTypes = {
		ValueChanged = "ValueChanged"
	},
	ReplicateTypes = {
		Single = "Single",
		All = "All"
	},
	RigTypes = {
		R15 = "R15",
		R6 = "R6"
	}
}

utils.getWalkDirection = function(Humanoid : Humanoid)
	local moveDirection
	local walkToPoint = Humanoid.WalkToPoint
	local walkToPart = Humanoid.WalkToPart
	if Humanoid.MoveDirection ~= Vector3.zero then
		moveDirection = Humanoid.MoveDirection
	elseif walkToPart or walkToPoint ~= Vector3.zero then
		local destination
		if walkToPart then
			destination = walkToPart.CFrame:PointToWorldSpace(walkToPoint)
		else
			destination = walkToPoint
		end
		local moveVector = Vector3.zero
		if Humanoid.RootPart then
			moveVector = destination - Humanoid.RootPart.CFrame.Position
			moveVector = Vector3.new(moveVector.x, 0.0, moveVector.z)
			local mag = moveVector.Magnitude
			if mag > 0.01 then
				moveVector /= mag
			end
		end
		moveDirection = moveVector
	else
		moveDirection = Humanoid.MoveDirection
	end
	
	local cframe = Humanoid.RootPart.CFrame
	local lookat = cframe.LookVector
	local direction = Vector3.new(lookat.X, 0.0, lookat.Z)
	direction = direction / direction.Magnitude --sensible upVector means this is non-zero.
	local ly = moveDirection:Dot(direction)
	if ly <= 0.0 and ly > -0.05 then
		ly = 0.0001 -- break quadrant ties in favor of forward-friendly strafes
	end
	local lx = direction.X*moveDirection.Z - direction.Z*moveDirection.X
	local tempDir = Vector2.new(lx, ly) -- root space moveDirection
	return tempDir
end

utils.addEnum = function(enumString : string, silentAssert : boolean)
	local split = string.split(enumString, ".")
	local parent = Constants
	for i, word in split do
		if not parent[word] then
			if i ~= #split then
				parent[word] = {}
			else
				parent[word] = word
				shared.debug(`Added new enum: {enumString}`)
			end
		else
			assert(i ~= #split or silentAssert, `{enumString} already exists as an enum!`)
			parent = parent[word]
		end
	end
end

utils.retrieveEnum = function(enumString : string)
	local split = string.split(enumString, ".")
	local parent = Constants
	for _, word in split do
		parent = parent[word]
		assert(parent, `{word} is not a valid namespace/enum!`)
	end
	return parent
end

-- Category: Event/Functions

-- Used to retrieve the events folder for either the client or the server
utils.retrieveEvents = function()
	return Remotes.Events, Bindables.Events
end

-- Used to retrieve the functions folder for either the client or the server
utils.retrieveFunctions = function()
	return Remotes.Functions, Bindables.Functions
end

--[[
A faster way of onClientEvent or onServerEvent without needing to get the event separately WITH easy to understand errors if you don't type in the name of an event right

Params:
nameOfEvent = Name of the event you want to connect to
func = The function you want to connect to the event
]]
utils.onRemoteEvent = function(nameOfEvent : string, func)
	local event : RemoteEvent = Remotes.Events:FindFirstChild(nameOfEvent)
	
	if event then
		if Player then
			return event.OnClientEvent:Connect(func)
		else
			return event.OnServerEvent:Connect(func)
		end
	else
		error("No RemoteEvent with the name "..nameOfEvent.." was found.")
	end
end

--[[
A faster way of Event without needing to get the event separately WITH easy to understand errors if you don't type in the name of an event right

Params:
nameOfEvent = Name of the event you want to connect to
func = The function you want to connect to the event
]]
utils.onEvent = function(nameOfEvent : string, func)
	local event : BindableEvent = Bindables.Events:FindFirstChild(nameOfEvent)
	if event then
		return event.Event:Connect(func)
	else
		error("No BindableEvent with the name "..nameOfEvent.." was found.")
	end
end

--[[
A faster way of firing a RemoteEvent/UnreliableRemoteEvent needing to get the event separately WITH easy to understand errors if you don't type in the name of an event right.

Params:
nameOfEvent = Name of the event you want to fire
specifiedPlayer = If on the server, this is the player that you want to fire the remote to. If there is no player specified, all players will get the event
]]
utils.FireRemote = function(nameOfEvent, specifiedPlayer : Player, ...)
	local event : RemoteEvent = Remotes.Events:FindFirstChild(nameOfEvent) or Remotes.Communicators:FindFirstChild(nameOfEvent)

	if event then
		if Player then
			event:FireServer(...)
		else
			if specifiedPlayer then
				event:FireClient(specifiedPlayer, ...)
			else
				event:FireAllClients(...)
			end
		end
	else
		error("No RemoteEvent with the name "..nameOfEvent.." was found.")
	end
end

utils.FireBindable = function(nameOfEvent, ...)
	local event : BindableEvent = Bindables.Events:FindFirstChild(nameOfEvent)
	if event then
		event:Fire(...)
	else
		error("No BindableEvent with the name "..nameOfEvent.." was found.")
	end
end

-- Gets the communicators for roles
utils.GetCommunicators = function()
	return Remotes.Communicators
end

-- Category: Misc Functions
-- Save copied tables in `copies`, indexed by original table.
function deepCopyTable(orig, copies)
	copies = copies or {}
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		if copies[orig] then
			copy = copies[orig]
		else
			copy = {}
			copies[orig] = copy
			for orig_key, orig_value in next, orig, nil do
				copy[deepCopyTable(orig_key, copies)] = deepCopyTable(orig_value, copies)
			end
			setmetatable(copy, deepCopyTable(getmetatable(orig), copies))
		end
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

-- Using the Fisher-Yates method
function utils.shuffle(t)
	--local rng = Random.new()
	local j
	for i = #t, 2, -1 do
		local j = math.random(1, i)--rng:NextInteger(1, i)
		t[j], t[i] = t[i], t[j]
	end
end

function utils.PartSeesPart(part1 : BasePart, part2 : BasePart, raycast : boolean, requiredAngle, optionalraycastparams : RaycastParams)
	if part1 ~= nil and part2 ~= nil then
		local Facing = part1.CFrame.LookVector
		local Vector = (part2.Position - part1.Position).Unit
		local Angle = math.acos(Facing:Dot(Vector))
		local seen = Angle < requiredAngle or math.pi*7/18 -- This default is the FOV of first person players

		if raycast and seen then -- If not seen, then no need to do a raycast lmao
			optionalraycastparams = optionalraycastparams or RaycastParams.new()
			local newRaycast = workspace:Raycast(part1.Position, part2.Position - part1.Position, optionalraycastparams)

			if newRaycast.Instance ~= part2 and (not part2:IsDescendantOf(newRaycast.Instance:FindFirstAncestorWhichIsA("Model")) or newRaycast.Instance.Parent == workspace) then
				seen = false
			end
		end

		return seen
	end
end

function utils.PartRaycastsToPart(part1 : BasePart, part2 : BasePart, optionalraycastparams : RaycastParams)
	local raycastSees = true

	optionalraycastparams = optionalraycastparams or RaycastParams.new()
	local newRaycast = workspace:Raycast(part1.Position, part2.Position - part1.Position, optionalraycastparams)

	if newRaycast then
		if newRaycast.Instance ~= part2 and (not part2:IsDescendantOf(newRaycast.Instance:FindFirstAncestorWhichIsA("Model")) or newRaycast.Instance.Parent == workspace) then
			raycastSees = false
		end
	end

	return raycastSees
end

--[[ 
Gets the closest matching player from a string
Params:
name - Player name
displayName - If nil, check for both display and non-display. If true, only check for display. If false, only check for name.
]]
function utils.GetPlayerFromName(name : string, displayName : boolean)
	if not name then return nil end
	name = name:lower()
	for _, player in Players:GetPlayers() do
		if ((displayName or displayName == nil) and player.DisplayName:lower():match(name)) -- If display name.
			or (not displayName and player.Name:lower():match(name)) then -- If not display name.
			return player -- Closest matching player
		end
	end
end

function utils.cloneDict(dict)
	local clonedDict = {}
	
	for index, value in dict do
		clonedDict[index] = (type(value) == 'table' and utils.cloneDict(value)) or value
	end
	
	return clonedDict
end

shared.Utils = utils
return utils

----------------------
-- Name: Utils
-- Author: LoxiGoose
-- Created: 11/12/2023
-- Last Updated: 12/3/2023
----------------------

local utils = {}
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Player = game:GetService("Players").LocalPlayer

-- Category: Event/Functions

-- Used to retrieve the events folder for either the client or the server
utils.retrieveEvents = function()
	if Player then
		return Remotes.Events
	else
		return Bindables.Events
	end
end

-- Used to retrieve the functions folder for either the client or the server
utils.retrieveFunctions = function()
	if Player then
		return Remotes.Functions
	else
		return Bindables.Functions
	end
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
	local event : RemoteEvent = Remotes.Events:FindFirstChild(nameOfEvent)

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

-- Can be used to confirm if we are a role
utils.GetCommunicators = function()
	if Player then
		local character = Player.Character
		if character then
			local CommunicateEvent : RemoteEvent = character:FindFirstChild("CommunicateEvent")
			local GetDataFunction : RemoteFunction = character:FindFirstChild("GetDataFunction")
			return CommunicateEvent, GetDataFunction
		end
	else
		warn("This can only be called on the client!")
	end
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
	local Facing = part1.CFrame.LookVector
	local Vector = (part2.Position - part1.Position).unit
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


return utils

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Settings = script.Parent.Parent:WaitForChild("Settings")
local groupId = 10874599
local util = {}


-- The C number is optional
function util.pythagoreanTheorem(a : number, b : number, c : number) : number
	c = c or 0

	return math.sqrt(a^2 + b^2 + c^2)
end


function util.solveDistance(Pos1 : Vector3, Pos2 : Vector3): number
	local D = Pos2 - Pos1 -- D for "Distance"
	return math.abs(util.pythagoreanTheorem(D.X,D.Y,D.Z))
end


local function getRemoteEvent(remoteName : string) : RemoteEvent
	local remote : RemoteEvent = Remotes:FindFirstChild(remoteName, true)
	util.assert(remote and remote:IsA("RemoteEvent"), `{remoteName} is not an existing remote event!`)
	return remote
end

local function getRemoteFunction(remoteName : string) : RemoteFunction
	local remote : RemoteFunction = Remotes:FindFirstChild(remoteName, true)
	util.assert(remote and remote:IsA("RemoteFunction"), `{remoteName} is not an existing remote function!`)
	return remote
end

-- Deep clone any table
-- @param tble : The table you want to clone
-- @return A clone of the given table
function util.deepClone(tble : {[any]:any}) : {[any]:any}
	local clone = {}

	for index, value in tble do
		-- quick mention that this is NOT a true clone for some values. Some of these are stored as references, e.g. functions.
		clone[index] = (type(value) == 'table' and util.deepClone(value)) or value
	end

	return clone
end

-- Fire a remote given its name
-- @param remoteName : The name of the remote
-- @param ... : Additional arguments to send. If you are running from the server, the first argument should be the player
function util.fireRemote(remoteName : string, ... : any)
	local remote = getRemoteEvent(remoteName)
	if(RunService:IsClient()) then
		remote:FireServer(...)
	else
		remote:FireClient(...)
	end
end

-- Run a function when a remote is fired
-- @param remoteName : The name of the remote
-- @param func : The function to run
-- @return The given RBXScriptConnection
function util.onRemote(remoteName : string, func : (...any) -> ()) : RBXScriptConnection
	local remote = getRemoteEvent(remoteName)
	if(RunService:IsClient()) then
		return remote.OnClientEvent:Connect(func)
	else
		return remote.OnServerEvent:Connect(func)
	end
end

-- Invoke a remote function
-- @param remoteName : The name of the remote
-- @param ... : Additional arguments to send
-- @return The returns from the remote
function util.invokeRemote(remoteName : string, ... : any) : any
	local remote = getRemoteFunction(remoteName)
	if(RunService:IsClient()) then
		return remote:InvokeServer(...)
	else
		return remote:InvokeClient(...)
	end
end

-- Run a function on invoke and return something
-- @param remoteName : The name of the remote
-- @param func : The function to use
function util.onInvoke(remoteName : string, func : (...any) -> (...any))
	local remote = getRemoteFunction(remoteName)
	if(RunService:IsClient()) then
		remote.OnClientInvoke = func
	else
		remote.OnServerInvoke = func
	end
end

-- A custom version of assert that is more performant than the built-in one
-- @param condition : The condition that you are checking against
-- @param message : The message you want to error with when the condition isn't met
function util.assert(condition : boolean, message : string)
	if(condition == nil or condition == false) then
		error(message)
	end	
end

-- Return whether the player is an admin of the game
-- @param player : The given player
-- @return Whether they are an admin or not
function util.isAdmin(player : Player)
	--return false
	return RunService:IsStudio() or player:GetRankInGroup(groupId) >= 254 or Settings:GetAttribute("Testing")
end

function util.isTester(player : Player)
	return RunService:IsStudio() or player:GetRankInGroup(groupId) >= 253
end

-- Get the walk direction of a humanoid
-- @param humanoid : The humanoid
-- @return Vector2 for directions
function util.getWalkDirection(humanoid : Humanoid)
	local moveDirection
	local walkToPoint = humanoid.WalkToPoint
	local walkToPart = humanoid.WalkToPart
	if humanoid.MoveDirection ~= Vector3.zero then
		moveDirection = humanoid.MoveDirection
	elseif walkToPart or walkToPoint ~= Vector3.zero then
		local destination
		if walkToPart then
			destination = walkToPart.CFrame:PointToWorldSpace(walkToPoint)
		else
			destination = walkToPoint
		end
		local moveVector = Vector3.zero
		if humanoid.RootPart then
			moveVector = destination - humanoid.RootPart.CFrame.Position
			moveVector = Vector3.new(moveVector.x, 0.0, moveVector.z)
			local mag = moveVector.Magnitude
			if mag > 0.01 then
				moveVector /= mag
			end
		end
		moveDirection = moveVector
	else
		moveDirection = humanoid.MoveDirection
	end

	local cframe = humanoid.RootPart.CFrame
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

-- Shuffle a table with the Fisher-Yates method
-- @param A table
-- @return The shuffled table
function util.shuffle(tble : {[any]:any})
	--local rng = Random.new()
	local j
	for i = #tble, 2, -1 do
		local j = math.random(1, i)--rng:NextInteger(1, i)
		tble[j], tble[i] = tble[i], tble[j]
	end
end

function util.length(tble : {[any]:any})
	local count = 0
	for _, _ in tble do
		count += 1
	end
	return count
end

function util.partSeesPart(part1 : BasePart, part2 : BasePart, raycast : boolean, requiredAngle : number?, raycastParams : RaycastParams?)
	if part1 ~= nil and part2 ~= nil then
		local Facing = part1.CFrame.LookVector
		local Vector = (part2.Position - part1.Position).Unit
		local angleToUse = (requiredAngle and requiredAngle / 2) or math.pi*7/18
		
		local angleToCompare = math.acos(Facing:Dot(Vector))
		if(requiredAngle) then angleToCompare = math.deg(angleToCompare) end
		local seen = angleToCompare < angleToUse -- This default is the FOV of first person players

		if raycast and seen then -- If not seen, then no need to do a raycast lmao
			seen = util.partRaycastsToPart(part1, part2, raycastParams)
		end
		
		return seen
	end
end

function util.playerSeesPart(part : BasePart, checkIfBehindWall : boolean, excludingParams : RaycastParams?)
	util.assert(RunService:IsClient(), "This is a client only method!")
	local _, sees = workspace.CurrentCamera:WorldToScreenPoint(part.Position)
	if(sees and checkIfBehindWall) then
		excludingParams = excludingParams or RaycastParams.new()
		excludingParams.FilterType = Enum.RaycastFilterType.Exclude
		if(Player.Character) then
			excludingParams:AddToFilter(Player.Character)
		end
		local newRaycast = workspace:Raycast(workspace.CurrentCamera.CFrame.Position, part.Position - workspace.CurrentCamera.CFrame.Position, excludingParams)
		if(newRaycast) then
			if(newRaycast.Instance ~= part and (not part:IsDescendantOf(newRaycast.Instance:FindFirstAncestorWhichIsA("Model")) or newRaycast.Instance.Parent == workspace)) then
				sees = false
			end
		end
	end
	return sees
end

function util.partRaycastsToPart(part1 : BasePart, part2 : BasePart, raycastParams : RaycastParams?)
	local raycastSees = true

	local newRaycast = workspace:Raycast(part1.Position, part2.Position - part1.Position, raycastParams)

	if newRaycast then
		if newRaycast.Instance ~= part2 and (not part2:IsDescendantOf(newRaycast.Instance:FindFirstAncestorWhichIsA("Model")) or newRaycast.Instance.Parent == workspace) then
			raycastSees = false
		end
	end

	return raycastSees
end

-- Gets the closest matching player from a string
-- @param name : Player name
-- @param displayName : If nil, check for both display and non-display. If true, only check for display. If false, only check for name.
-- @return The player that best matches the name
function util.getPlayerFromName(name : string, displayName : boolean)
	if not name then return nil end
	name = name:lower()
	for _, player in Players:GetPlayers() do
		if(displayName ~= false and player.DisplayName:lower():match(name)) -- If display name.
			or (not displayName and player.Name:lower():match(name)) then -- If not display name.
			return player -- Closest matching player
		end
	end
end

return util
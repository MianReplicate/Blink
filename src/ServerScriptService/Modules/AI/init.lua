local ServerScriptStorage = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RModules = ReplicatedStorage:WaitForChild("Modules")
local SModules = ServerScriptStorage:WaitForChild("Modules")
local Util = require(RModules:WaitForChild("Util"))
local DataCreator = require(SModules:WaitForChild("DataCreator"))
local GameLibrary = require(SModules:WaitForChild("GameLibrary"))

local ai = {}

local runningAI = DataCreator.new("List", "AI")
local createdGoals = {}

-- Creates a new goal. Do not worry about this. Goals are created by placing a module beneath this.
local function createGoal(name : string, func : (data : DataCreator.Data) -> ())
	createdGoals[name] = func
end

-- Create a new AI that will have its goals ticked
-- @param identifier : Any identifier that you wish to identify your AI by
-- @param goals : What goals to attach to this AI. Order matters!
-- @return The AI data (from the DataCreator module)
function ai.createAI(identifier : any, goals : {string}) : DataCreator.Data
	for _, goal in goals do
		Util.assert(createdGoals[goal], `{goal} is not a valid created goal!`)
	end	
	
	local aiData = DataCreator.new("AI", identifier)
	
	local usedGoals = {}
	for _, goal in goals do
		usedGoals[goal] = createdGoals[goal]
	end
	
	aiData:setValue("Goals", usedGoals)
	runningAI:addValue(aiData)
	
	return aiData
end

-- This removes the AI permanently (don't kill bots :<)
-- @param aiData : The AI to remove
function ai.removeAI(aiData : DataCreator.Data)
	local i = runningAI:findValue(aiData)
	print(i)
	if(i) then
		runningAI:removeValue(i)
		aiData:remove()
	end
end

-- Kills all AIs lmao
function ai.killAIs()
	for _, _ai : DataCreator.Data in runningAI:getStorage() do
		_ai:remove()
	end
end

-- Creates goals, don't worry about this. This is automatic :)
for _, goalModule : ModuleScript in script:GetChildren() do
	if(not goalModule:IsA("ModuleScript")) then continue end
	
	local goal = require(goalModule)
	Util.assert(typeof(goal)=='function',`{goalModule.Name} is not a valid goal!`)
	createGoal(goalModule.Name, goal)
end

local function GetNearbySurvivorsCount(PlayerCharacter : Model):number
	
	local MinimumDistance = 32 -- How close a player is to be defined as in a "group" together
	
	
	local Survivors = GameLibrary.getSurvivors(true)
	local Count = 0 -- Keeps track of the total players
	local Players = {}
	local Pos1 = PlayerCharacter.HumanoidRootPart.Position
	
	
	for character, data in Survivors do
		
		local Pos2 = character.HumanoidRootPart.Position
		
		if Pos1 == Pos2 then
			continue
		end
		
		if Util.SolveDistance(Pos1, Pos2) <= MinimumDistance then
			Count += 1
			table.insert(Players, character)
		end
		
	end
	
	return Count, Players
end


function ai.GetSurvivorGroupTypes()
	local Survivors = GameLibrary.getSurvivors(true)
	for character, data in Survivors do
		local Count, players = GetNearbySurvivorsCount(character)
		print(character, Count, players)
	end
end


--while task.wait(1.5) do
--	AI.GetSurvivorGroupTypes()
--end


return ai
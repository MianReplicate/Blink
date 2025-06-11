local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Modules = ServerScriptService:WaitForChild("Modules")
local RModules = ReplicatedStorage:WaitForChild("Modules")
local RoleCommunication = require(RModules:WaitForChild("RoleCommunication"))
local DataCreator = require(Modules:WaitForChild("DataCreator"))
local Util = require(RModules:WaitForChild("Util"))
local Sounds = ReplicatedStorage:WaitForChild("Sounds")

local tools = DataCreator.newOrGet("List", "Tools")
local tool = {}

function tool:setToolType()
	
end

return tool

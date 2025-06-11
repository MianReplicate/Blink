local GameLibrary = require(game.ServerScriptService.Modules:WaitForChild("GameLibrary"))
local DataCreator = require(game.ServerScriptService.Modules.DataCreator)
local dummy = script.Parent
local Players = game:GetService("Players")

local angel = GameLibrary.createOrGetAngel(dummy)
--task.wait(1)
--angel:kill()
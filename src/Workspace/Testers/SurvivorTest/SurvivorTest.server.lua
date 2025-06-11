local GameLibrary = require(game.ServerScriptService.Modules:WaitForChild("GameLibrary"))
local DataCreator = require(game.ServerScriptService.Modules.DataCreator)
local Players = game:GetService("Players")

local survivor = GameLibrary.createOrGetSurvivor(script.Parent)

--while task.wait(math.random(1, 2)) do
--	local times = math.random(1, 3)
--	repeat
--		survivor:strain()
--		times-=1
--	until times <= 0
--end
task.wait(2)
survivor:kill()
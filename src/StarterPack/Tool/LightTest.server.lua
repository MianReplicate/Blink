local GameLibrary = require(game.ServerScriptService.Modules:WaitForChild("GameLibrary"))
local DataCreator = require(game.ServerScriptService.Modules.DataCreator)
local lightInstance = script.Parent

local light = GameLibrary.createOrGetLight(lightInstance, lightInstance.Handle)
--light:setStrengthModifier("Hurt", -5)
--light:queueFlicker(true)
--task.wait(4)
--light:queueFlicker(false)
--task.wait(2)
--light:queueFlicker(true)
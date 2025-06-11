local GameLibrary = require(game.ServerScriptService.Modules:WaitForChild("GameLibrary"))
local DataCreator = require(game.ServerScriptService.Modules.DataCreator)
local lightInstance = script.Parent

local light = GameLibrary.createOrGetLight(lightInstance, lightInstance.ligh)
--light:setStrengthModifier("Hurt", -5)
--task.wait(7)
--light:queueFlicker(true)
--task.wait(5)
--light:queueFlicker(false)
--task.wait(4)
--light:queueFlicker(false)
--task.wait(2)
--light:queueFlicker(true)
local flicker = false
script.Parent.ligh.ClickDetector.MouseClick:Connect(function()
	flicker = not flicker
	light:editFlickerReason("isaidso", flicker)
end)
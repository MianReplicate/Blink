local gameLibrary = require(script.Parent)

task.wait(3)
local roleData = gameLibrary.transformPlayerIntoRole(game.Players.LoxiGoose, nil, nil, "Survivor")
roleData:sendInfoToClient("hi")
task.wait(3)
gameLibrary.removeRoleCharacter(workspace:WaitForChild("LoxiGoose"))
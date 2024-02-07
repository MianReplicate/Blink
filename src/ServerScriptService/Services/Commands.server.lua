----------------------
-- Name: Commands
-- Author: LoxiGoose
-- Created: 11/12/2023
-- Last Updated: 11/12/2023
----------------------

local ServerScriptService = game:GetService("ServerScriptService")
local GameLibrary = require(ServerScriptService:WaitForChild("Modules"):WaitForChild("GameLibrary"))
local Players = game:GetService("Players")
local commandPrefix = "/"

local commands = {
	printMsg = function(args, player : Player)
		local msg = args[1]
		table.remove(args, 1)
		if msg then
			for _, word in args do
				msg = msg.." "..word
			end
			print(msg)
		end
	end,
	becomerole = function(args, player : Player)
		local role = string.lower(args[1])
		player = args[2] or player
		
		if role then
			if role == "wa" then
				GameLibrary.transformPlayerIntoRole(player, nil, nil, "Weeping Angel")
			elseif role == "su" then
				GameLibrary.transformPlayerIntoRole(player, nil, nil, "Survivor")
			end
		end
	end,
}

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if string.sub(message, 1, 1) == commandPrefix then
			local commandMsgWithParams = string.sub(message, 2)
			local seperatedCmdMsg = string.split(commandMsgWithParams, " ")
			local commandMsg = seperatedCmdMsg[1]
			table.remove(seperatedCmdMsg, 1)
			
			if commands[commandMsg] then
				local success, errormsg = pcall(function()
					commands[commandMsg](seperatedCmdMsg, player)
				end)
				
				if success then
					print(commandMsg.. " command was successful.")
				else
					warn("Command failed to run!")
					error(errormsg)
				end
			else
				warn(commandMsg.." command was not found.")
			end
		end
	end)
end)
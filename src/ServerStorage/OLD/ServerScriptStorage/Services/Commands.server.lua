----------------------
-- Name: Commands
-- Author: MianReplicate
-- Created: 11/12/2023
----------------------

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local commandPrefix = "/"

local commands = {
	printMsg = function(player : Player, args)
		local msg = args[1]
		table.remove(args, 1)
		if msg then
			for _, word in args do
				msg = msg.." "..word
			end
			print(msg)
		end
	end,
	becomerole = function(player : Player, args)
		local role = string.lower(args[1])
		player = (shared.Utils.GetPlayerFromName(args[2], true)) or player -- Improve on the player finding. We will probably have a function to locate a player easily with their name

		if role then
			if role == "wa" then
				--shared.GameLibrary.transformPlayerIntoRole(player, nil, nil, shared.Constants.RoleTypes.Angel)
				shared.GameLibrary.transformPlayerIntoRole(player, shared.Utils.retrieveEnum("RigTypes.R15"), nil, shared.Utils.retrieveEnum("SubTypes.Angel"))
			elseif role == "su" then
				--shared.GameLibrary.transformPlayerIntoRole(player, nil, nil, shared.Constants.RoleTypes.Survivor)
				shared.GameLibrary.transformPlayerIntoRole(player, shared.Utils.retrieveEnum("RigTypes.R15"), nil, shared.Utils.retrieveEnum("SubTypes.Survivor"))
			else
				error(`{role} is not a role!`)
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
					commands[commandMsg](player, seperatedCmdMsg)
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
----------------------
-- Name: Players
-- Authors: MianReplicate
-- Created: 12/31/2024
-- Purpose: To handle players
----------------------
local Modules = script.Parent:WaitForChild("Modules")
local GameLibrary = require(Modules:WaitForChild("GameLibrary"))
local DataCreator = require(Modules:WaitForChild("DataCreator"))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = ReplicatedStorage:WaitForChild("Settings")
local RModules = ReplicatedStorage:WaitForChild("Modules")
local Util = require(RModules:WaitForChild("Util"))
local Players = game:GetService("Players")

local commands = {}

function commands.print(player : Player, ...)
	return ...
end

function commands.becomerole(player : Player, role : string, optionalPlayerName : string)
	player = (optionalPlayerName and Util.getPlayerFromName(optionalPlayerName, true)) or player
	GameLibrary.changeIntoRole(player, role)
end

function commands.createTool(player : Player, tool : string)
	
end

local prefix = "/"

local function handleCommand(player : Player, message : string)
	if(not Util.isAdmin(player)) then return end
	
	local indexStart = message:find(prefix)
	if(indexStart == 1) then
		message = message:sub(2)
		local split = message:split(" ")
		local command = split[1]:lower()
		table.remove(split, 1)
		
		local commandFunc : (...any) -> any = commands[command]
		if(commandFunc) then
			commandFunc(player, table.unpack(split))
		else
			warn(`{command} is not a valid command! | Used by {player}`)
		end
	end
end

local function saveData(playerData : Data.Data)
	
end

Players.PlayerAdded:Connect(function(player)
	--local playerData : Data.Data = DataCreator.new("Players", player)
	--local function isOwner(_player : Player) return _player == player end
	--playerData:setValue("Coins", 0)
	--playerData:setKeyChecks({"Coins"}, isOwner)
	--playerData:setAccessCheck(isOwner)
	if(Settings:GetAttribute("Testing")) then
		if(not Util.isTester(player)) then player:Kick("Must be a tester to join!") end
	end
	
	player.Chatted:Connect(function(message: string)
		handleCommand(player, message)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	
end)
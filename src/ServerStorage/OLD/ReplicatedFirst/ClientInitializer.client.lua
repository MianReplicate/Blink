----------------------
-- Name: ClientInitializer
-- Author: MianReplicate
-- Created 6/1/2024
-- Last Updated: 6/1/2024
----------------------

local rep = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local mods = rep:WaitForChild("Modules")
local commonInit = require(mods:WaitForChild("CommonInitializer"))

commonInit.initialize({
	ReplicatedStorage = {
		"Utils"
	}
}, 
{
	[players.LocalPlayer.PlayerScripts:WaitForChild("Services")] = {
		"WalletCache",
		"RetrieveTypes",
		"LightingProfiler",
		
		-- Handlers
		"CommonHandler",
		"RoleHandler"
	}
})
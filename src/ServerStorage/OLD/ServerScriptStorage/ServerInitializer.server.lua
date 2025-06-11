----------------------
-- Name: ServerInitializer
-- Author: MianReplicate
-- Created 6/1/2024
-- Last Updated: 6/1/2024
----------------------

local rep = game:GetService("ReplicatedStorage")
local mods = rep:WaitForChild("Modules")
local commonInit = require(mods:WaitForChild("CommonInitializer"))

commonInit.initialize({
	ServerScriptService = {
		"WalletCache",
		"GameLibrary"
	},
	ReplicatedStorage = {
		"Utils"
	}
}, 
{
	[script.Parent:WaitForChild("Services")] = 
		{
			"MainService",
			"CommunicationService",
			"LightingHandler",
			"Commands"
		}
}
)
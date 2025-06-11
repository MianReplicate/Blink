local char = script.Parent
local Rep = game:GetService("ReplicatedStorage")

local ragdollModule = require(game:GetService("ServerScriptService"):WaitForChild("Modules"):WaitForChild("RagdollModule"))
local ragdoll = ragdollModule.new(char, true)
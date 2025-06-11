----------------------
-- Name: WalletCache
-- Authors: MianReplicate
-- Created: 5/31/2024
----------------------
local replicate = {}
local RepStorage = game:GetService("ReplicatedStorage")
local Replicate = RepStorage:WaitForChild("Remotes"):WaitForChild("Events"):WaitForChild("WalletCache")
local Players = game:GetService("Players")

function replicateAllToPlayer(player : Player)
	for namespace, dict in _G do
		if dict.replicate then
			Replicate:FireClient(player, shared.Utils.retrieveEnum("ReplicateTypes.All"), namespace, dict.contents)
		end
	end
end

function crawlFromAncestors(namespace, ancestors)
	local dict = _G[namespace]
	local pos = dict.contents
	for _, parent in ancestors do
		pos = pos[parent]
		if pos == nil then warn(`{parent} does not exist within {namespace}!`) return end
	end
	return pos
end

function replicate.getNamespace(namespace)
	local dict = _G[namespace]
	if not dict then warn(`{namespace} is not a namespace that exists!`) return nil end
	local functions = {}
	function functions.addValue(value : any, ancestors)
		local key = #crawlFromAncestors(namespace, ancestors or {}) + 1
		functions.setValue(key, value, ancestors)
	end
	function functions.removeValue(value : any, ancestors)
		local pos = crawlFromAncestors(namespace, ancestors or {})
		local key = table.find(pos, value)

		if key then
			functions.setValue(key, nil, ancestors)
		end
	end
	function functions.setValue(key : any, value : any, ancestors)
		local pos = crawlFromAncestors(namespace, ancestors or {})
		pos[key] = value
		if dict.replicate then
			Replicate:FireAllClients(shared.Utils.retrieveEnum("ReplicateTypes.Single"), namespace, ancestors, key, value)
		end
	end
	function functions.getValue(key : any, ancestors)
		local pos = crawlFromAncestors(namespace, ancestors or {})
		return pos[key]
	end

	return functions
end

function replicate.createNamespace(namespace, replicate_, saved, contents)
	if _G[namespace] then warn(`{namespace} already exists!`) return end
	_G[namespace] = {
		replicate=replicate_,saved=saved,contents=contents
	}
	if replicate_ then
		Replicate:FireAllClients(shared.Utils.retrieveEnum("ReplicateTypes.All"), namespace, contents)
	end
	return replicate.getNamespace(namespace)
end

Players.PlayerAdded:Connect(function(player)
	replicateAllToPlayer(player)
end)

shared.WalletCache = replicate
return replicate
----------------------
-- Name: WalletCache
-- Author: LoxiGoose
-- Created: 11/10/2023
-- Last Updated: 12/4/2023
----------------------

local global = _G
local replicatedService = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local module = {}

local serverEvent
local syncEvent

function createEvents()
	if runService:IsServer() then
		serverEvent = Instance.new("BindableEvent")
		syncEvent = Instance.new("RemoteEvent")

		serverEvent.Name = "WalletEvent"
		syncEvent.Name = "WalletSyncEvent"

		serverEvent.Parent = script
		syncEvent.Parent = script
	else
		serverEvent = script:FindFirstChild("WalletEvent")
		syncEvent = script:FindFirstChild("WalletSyncEvent")
	end
end

createEvents()

function setValue(namespace, keyname, value)
	global[namespace][keyname] = value
	
	serverEvent:Fire(namespace, keyname, value)
end

if runService:IsServer() then
	function module.setValue(namespace, keyname, value)
		setValue(namespace, keyname, value)
	end

	function module.setValues(namespaces, keyname, value)
		for _, namespace in namespaces do
			setValue(namespace, keyname, value)
		end
	end
end

function module.onUpdate(namespaceonUpdate, func)
	if runService:IsServer() then
		return serverEvent.Event:Connect(function(namespace, keyname, value)
			if namespace == namespaceonUpdate then
				syncEvent:FireAllClients(namespace, keyname, value)
				func(keyname, value)
			end
		end)
	else
		return syncEvent.OnClientEvent:Connect(function(namespace, keyname, value)
			if namespaceonUpdate == namespace then
				func(keyname, value)
			end
		end)
	end
end

function module.getValue(valueIndex, ...)
	if runService:IsStudio() then
		local parent = global
		for index, parent_ in ... do
			parent = parent[parent_]
		end
		
		return parent[valueIndex]
	end
end

return module

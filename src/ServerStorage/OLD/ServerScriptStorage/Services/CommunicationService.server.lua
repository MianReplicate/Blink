----------------------
-- Name: CommunicationService
-- Authors: MianReplicate
-- Created: 5/31/2024
----------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local communicators = shared.Utils.GetCommunicators()
local remotes, bindables = shared.Utils.retrieveFunctions()

shared.Utils.onEvent("OnRoleAdded", function(roleType : string, character : Model)
	shared.Utils.FireRemote("OnRoleAdded", nil, roleType, character)
end)

communicators.ChangeValueForData.OnServerInvoke = function(player : Player, datatypeString : string, identifier : any, ancestry : {any}, newValue : any)
	local datatype = shared.DataRegistry.getType(datatypeString)
	if datatype and datatype.dataInfo.settings.replicateType then
		local data = datatype:getData(identifier)
		if data then
			return data:requestValueFor(player,ancestry,newValue)
		end
	end
end

communicators.GetValueFromData.OnServerInvoke = function(player : Player, datatypeString : string, identifier : any, ancestry : {any})
	local datatype = shared.DataRegistry.getType(datatypeString)
	if datatype and datatype.dataInfo.settings.replicateType then
		local data = datatype:getData(identifier)
		if data then
			return data:requestValueFor(player,ancestry)
		end
	end
end

communicators.CommunicateEvent.OnServerEvent:Connect(function(player : Player, datatypeString : string, identifier : any, funcName : any, ... : any)
	local datatype = shared.DataRegistry.getType(datatypeString)
	if datatype and datatype.dataInfo.settings.replicateType then
		local data = datatype:getData(identifier)
		if data then
			data:requestFunctionFor(player,funcName,...)
		end
	end
end)

remotes.GetRoleType.OnServerInvoke = function(player : Player)
	local data = shared.DataRegistry.getType(shared.Utils.retrieveEnum("DataTypes.Roles")):getData(player.Character)
	if data then
		return data.subtype
	end
end

remotes.RetrieveTypes.OnServerInvoke = function(player)
	return shared.DataRegistry.getDataInfos(true)
end
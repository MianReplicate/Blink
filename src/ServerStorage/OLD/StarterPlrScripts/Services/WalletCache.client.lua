----------------------
-- Name: WalletCache
-- Authors: MianReplicate
-- Created: 5/31/2024
----------------------
shared.Utils.onRemoteEvent("WalletCache", function(replicateType, namespace, ...)
	local args = {...}
	local ancestorsOrContents, key, value = args[1] or {}, args[2], args[3]
	
	if replicateType == shared.Utils.retrieveEnum("ReplicateTypes.All") then
		_G[namespace] = ancestorsOrContents
	else
		_G[namespace] = _G[namespace] or {}
		local pos = _G[namespace]
		for _, ancestor in ancestorsOrContents do
			pos[ancestor] = pos[ancestor] or {}
			pos = pos[ancestor]
		end
		pos[key] = value
	end
end)
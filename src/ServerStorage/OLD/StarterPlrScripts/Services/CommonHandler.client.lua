local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Player = Players.LocalPlayer
local communicators = shared.Utils.GetCommunicators()

local lightingSettings = {
	
}

function roleAdded()

end

function roleRemoved()

end

communicators.CommunicateEvent.OnClientEvent:Connect(function(datainfo, data)
	if datainfo.packettype == shared.Utils.retrieveEnum("PacketTypes.ValueChanged") then
		print(data)
	end
end)

communicators.ChangeValueForData:InvokeServer(shared.Utils.retrieveEnum("DataTypes.Players"), Player, {"currentArea"}, 3)
print(communicators.GetValueFromData:InvokeServer(shared.Utils.retrieveEnum("DataTypes.Players"), Player, {"currentArea"}))
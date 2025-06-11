local remotes, bindables = shared.Utils.retrieveFunctions()

function crawlSubtypes(subtypes)
	for name, subtype in subtypes do
		shared.Utils.addEnum(`SubTypes.{name}`, true)
		crawlSubtypes(subtype)
	end
end

for name, dataInfo in remotes.RetrieveTypes:InvokeServer() do
	shared.Utils.addEnum(`DataTypes.{name}`)
	crawlSubtypes(dataInfo.subTypes)
	for _, name in dataInfo.packetTypes do
		shared.Utils.addEnum(`PacketTypes.{name}`, true)
	end
end

script:SetAttribute("WaitTillComplete", true)
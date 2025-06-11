local ByteNet = require(script.Parent.ByteNetMax)

return ByteNet.defineNamespace("Data", function()
	return {
		packets = {
			DataCreated = ByteNet.definePacket({
				value = ByteNet.struct({
					storageIdentifier=ByteNet.string,
					tag=ByteNet.string,
					object=ByteNet.string,
					storage=ByteNet.map(ByteNet.unknown, ByteNet.unknown),
					objectMetadata=ByteNet.struct({
						isInstance=ByteNet.bool
					}),
					version=ByteNet.uint32,
				})
			}),
			DataRemoved = ByteNet.definePacket({
				value = ByteNet.struct({
					tag=ByteNet.string,
					object=ByteNet.string,
					objectMetadata=ByteNet.struct({
						isInstance=ByteNet.bool
					})
				})
			}),
			ValueChanged = ByteNet.definePacket({
				value = ByteNet.struct({
					storageIdentifier=ByteNet.string,
					tag=ByteNet.string,
					object=ByteNet.string,
					key=ByteNet.unknown,
					value=ByteNet.optional(ByteNet.unknown),
					version=ByteNet.uint32
				})
			}),
			QuickReplicateAll = ByteNet.definePacket({
				value = ByteNet.nothing
			}),
			ValueEdited = ByteNet.definePacket({
				value = ByteNet.struct({
					tag=ByteNet.string,
					object=ByteNet.string,
					key=ByteNet.unknown,
					value=ByteNet.optional(ByteNet.unknown)
				})
			})
		},
		queries = {
			GetInstanceFromUUID = ByteNet.defineQuery({
				request = ByteNet.string,
				response = ByteNet.optional(ByteNet.inst)
			}),
			GetUUIDFromInstance = ByteNet.defineQuery({
				request = ByteNet.inst,
				response = ByteNet.optional(ByteNet.string)
			})
		}
	}
end)

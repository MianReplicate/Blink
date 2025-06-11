local ByteNet = require(script.Parent.ByteNetMax)

return ByteNet.defineNamespace("Roles", function()
	return {
		packets = {
			RoleAction = ByteNet.definePacket({
				value = ByteNet.string
			}),
			RoleChange = ByteNet.definePacket({
				value = ByteNet.string
			}),
			WatchingAngels = ByteNet.definePacket({
				value = ByteNet.array(ByteNet.inst)
			}),
			Freeze = ByteNet.definePacket({
				value = ByteNet.bool
			}),
			UseAbility = ByteNet.definePacket({
				value = ByteNet.struct({
					abilityType = ByteNet.string,
					toggled=ByteNet.optional(ByteNet.bool)
				})
			})
		}
	}
end)

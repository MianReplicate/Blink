----------------------
-- Name: Players
-- Authors: MianReplicate
-- Created: 7/22/2024
----------------------
local Data = require(script.Parent)

local datainfo : Data.DataInfo = {
	subTypes = {
		Common = {
			init = function(data)
				local player = data:getValue('identifier')
				local areas = {"MainMenu", "Lobby", "Round"}
				data:setMultipleValues({
					currentArea = 1,
					areas = areas,
					changeArea = function(area)
						local index = table.find(areas, area)
						if index and data:getValue("currentArea") ~= index then
							data:setValue("currentArea", index)
							data:sendPacket({player}, shared.Utils.retrieveEnum("PacketTypes.AreaChanged"), areas[index])
						else
							warn(`{area} is not a valid area to change to or the player is already in that area!`)
						end
					end,
				})
				data:addRequestableIndexesFor("Editables", {player}, true, {"currentArea"})
				print(`i got created for {player} :)))`)
			end,
		}
	},
	packetTypes = {
		"AreaChanged"
	},
	settings = {
		replicateType = true,
	}
}

return datainfo
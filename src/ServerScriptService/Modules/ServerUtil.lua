local DataCreator = require(script.Parent.DataCreator)
local util = {}

local angels = DataCreator.newOrGet("List", "Angels")



local function getAliveAngels()
	local storage = angels:getStorage()
	local realStorage = {}
	for character, angel in storage do
		local instance = DataCreator.getInstanceFromUUID(character)
		if(not instance) then continue end
		if(not angel:getData():getValue("dead")) then
			realStorage[instance] = angel
		end
	end
	
	return realStorage
end


function util.removeWatchingAngelsForCharacter(character : Model, specificAngelsToRemove)
	local angels = specificAngelsToRemove or getAliveAngels()
	for _, angel : Angel in angels do
		local angelData = angel:getData()
		if(not angelData:getValue("dead")) then
			local beingWatchedBy : DataCreator.Data = angelData:getValue("beingWatchedBy")
			local i = beingWatchedBy:findValue(character)
			if(i) then
				beingWatchedBy:setValue(i, nil)
			end
			--beingWatchedBy:setValue(character, nil)
		end
	end
end

return util

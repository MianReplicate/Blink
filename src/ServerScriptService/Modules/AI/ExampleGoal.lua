local DataCreator = require(game:GetService("ServerScriptService"):WaitForChild("Modules"):WaitForChild("DataCreator"))

-- Goals are passed aiData
return function(aiData : DataCreator.Data) : boolean
	local seconds = aiData:getValue("currentTime")
	
	if(not seconds or (seconds and os.clock() - seconds > 1)) then
		aiData:setValue("currentTime", os.clock())
		print("A second passed")
		return true
	end
	
	return false
end

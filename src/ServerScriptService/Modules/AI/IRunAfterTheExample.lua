local DataCreator = require(game:GetService("ServerScriptService"):WaitForChild("Modules"):WaitForChild("DataCreator"))

return function(aiData : DataCreator.Data)
	print("hi, i'm a fallback!")
	return true
end

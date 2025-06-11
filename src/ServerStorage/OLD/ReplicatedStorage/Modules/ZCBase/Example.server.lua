local module = require(script.Parent) -- link to ZCBase obviously
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(Player)
	-- FINE THEM FOR 1 MILLION DOLLARS!!!!
	
	-- create a local ZCBase instance for them
	local instance = module.new(Player.UserId, false, "BlinkBucks") -- UserID, Save To Datastore, Currency Type
	
	instance:AddTransaction(
		instance:CreateTransactionInfo(
			"BlinkBucks",
			"GOD",
			1000000, -- COST
			1, -- we are good guys and only fine once
			"FEE OF ENTRY"
		)
	)
	
	-- player has been fined
end)
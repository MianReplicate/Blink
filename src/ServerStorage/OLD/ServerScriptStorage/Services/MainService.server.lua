local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local GameLibrary = require(script.Parent.Parent.Modules.GameLibrary)

Players.PlayerAdded:Connect(shared.GameLibrary.onPlayerAdded)
Players.PlayerRemoving:Connect(shared.GameLibrary.onPlayerRemoved)

RunService.Heartbeat:Connect(function()
	local roleDatas = GameLibrary.getRoleDatas()
	for identifier, data in roleDatas do
		task.spawn(function()
			local dataInfo = data:getDataInfo()
			local character = data:getValue("identifier")
			if character then
				local Humanoid : Humanoid = character:FindFirstChildWhichIsA("Humanoid")
				local dead = true
				if Humanoid then
					if Humanoid.Health > 0 then
						dead = false
						-- Common code
						
						-- Survivor code
						if dataInfo.da == shared.Utils.retrieveEnum("SubTypes.Survivor") then
							local walkDirection = shared.Utils.getWalkDirection(Humanoid)
							if walkDirection.Y < 0 then
								character.Humanoid.WalkSpeed = 10
							else
								character.Humanoid.WalkSpeed = 16
							end
						end
						
						-- Angel code
					end
				end
				
				if dead then
					data.died()
				end
			end
		end)
	end
end)
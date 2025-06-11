local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ServerModules = script.Parent:WaitForChild("Modules")
local Util = require(Modules:WaitForChild("Util"))
local GameLibrary = require(ServerModules:WaitForChild("GameLibrary"))
local DataCreator = require(ServerModules:WaitForChild("DataCreator"))
local RoleCommunication = require(Modules:WaitForChild("RoleCommunication"))
local ServerUtil = require(ServerModules:WaitForChild("ServerUtil"))

RoleCommunication.packets.RoleAction.listen(function(funcName : string, player : Player)
	if(player.Character) then
		local roleData = GameLibrary.getRoleDataFromCharacter(player.Character)
		if(roleData) then
			local data : DataCreator.Data = roleData:getData()
			if(table.find(data:getValue("allowedFunctions"), funcName)) then
				roleData[funcName](roleData)
			end
		end
	end
end)

RoleCommunication.packets.WatchingAngels.listen(function(angels, player)
	if(player.Character and player.Character:FindFirstChild("HumanoidRootPart")) then
		local roleData = GameLibrary.getRoleDataFromCharacter(player.Character)
		if(roleData) then
			local data : DataCreator.Data = roleData:getData()
			if(data and not data:getValue("dead") and not data:getValue("blinking")) then
				local angelsToRemove = GameLibrary.getAngels()
				
				for _, angel : Instance in angels do
					local angelData = GameLibrary.getRoleDataFromCharacter(angel)
					if(angelData and not angelData:getData():getValue("dead")) then
						local beingWatchedBy : DataCreator.Data = angelData:getData():getValue("beingWatchedBy")
						local raycastParams = RaycastParams.new()
						raycastParams.FilterType = Enum.RaycastFilterType.Exclude
						raycastParams:AddToFilter(player.Character)
						if(Util.partRaycastsToPart(player.Character.HumanoidRootPart, angel.HumanoidRootPart, raycastParams)) then
							if(not beingWatchedBy:findValue(player.Character)) then
								beingWatchedBy:addValue(player.Character)
							end
							angelsToRemove[angel] = nil
						end
					end
				end
				
				ServerUtil.removeWatchingAngelsForCharacter(data:getObject(), angelsToRemove)
				data:setValue("watchingAngelsTime", os.clock())
			end
		end
	end
end)

RoleCommunication.packets.UseAbility.listen(function(data, player)
	if(player.Character and player.Character:FindFirstChild("HumanoidRootPart")) then
		local roleData : GameLibrary.Angel = GameLibrary.getRoleDataFromCharacter(player.Character, "Angel")
		if(roleData) then
			roleData:toggleAbility(data.abilityType, data.toggled)
		end
	end
end)
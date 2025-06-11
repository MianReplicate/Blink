-- OUTDATED!! THE LOCALSCRIPT IS UNDER STARTERPLAYERSCRIPTS!! --

----------------------
-- Name: LightingHandler
-- Author: Zetalasis (@zetalasis), MianReplicate
-- Created 5/31/2024
-- Last Updated: 5/31/2024
----------------------

-- Controls Lighting for easy swappable configurations

--local Lighting = game:GetService("Lighting")

--Lighting.ChildAdded:Connect(function(instance)
--	-- a folder will be added to swap out config

--	if instance:IsA("Folder") then
--		local IsLightingConfig = instance:GetAttribute("LightingConfig")
--		if IsLightingConfig then
--			-- clear out lighting in preperation for new config
--			for _, v in Lighting:GetChildren() do
--				if v ~= instance then
--					v:Destroy()
--					continue
--				end
--			end

--			-- set lighting stuffs
--			-- will possibly contain lighting effects like sky, atmosphere, color correction, etc

--			local config = instance:FindFirstChildWhichIsA("Configuration")
--			local children = instance:GetChildren()

--			for _, v in children do
--				if not v:IsA("Configuration") and not v:IsA("BoolValue") then -- probably a lighting effect then
--					-- clone it then parent it to lighting
--					-- so we dont lose it in the config

--					local clone = v:Clone()
--					clone.Parent = Lighting
--				end
--			end

--			if config then
--				for _, v in config:GetChildren() do
--					Lighting[v.Name] = v.Value
--				end
--			end
--		end
--	end
--end)
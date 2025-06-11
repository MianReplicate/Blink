game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		-- keep BallSocketConstraints on death
		humanoid.BreakJointsOnDeath = false
		-- avoid HRP colliding with UpperTorso on death
		character.HumanoidRootPart.CanCollide = false

		humanoid.Died:Connect(function()
			character.Head.CanCollide = true
			print("died!")
			for _, joint in character:GetDescendants() do
				if joint:IsA("AnimationConstraint") then
					joint.Enabled = false
				elseif joint:IsA("BallSocketConstraint") then
					joint.MaxFrictionTorque = 1
				end
			end
		end)

	end)
end)
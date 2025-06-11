game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		
		wait()
		
		local M6D = Instance.new("Motor6D")
		M6D.Name = "ToolAttach"
		M6D.Parent = character.RightHand
		
		character.ChildAdded:Connect(function(child)
			
			if child:IsA("Tool") and child:FindFirstChild("Main") then
				M6D.Part1 = child.Main
			end
			
		end)
		
	end)
	
end)
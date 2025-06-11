local character = script.Parent:WaitForChild("Tester")

character.Parent = nil

while task.wait(3) do
	local clone = character:Clone()
	local humanoid = clone:WaitForChild("Humanoid")
	-- keep BallSocketConstraints on death
	humanoid.BreakJointsOnDeath = false
	-- avoid HRP colliding with UpperTorso on death
	clone.HumanoidRootPart.CanCollide = false
	
	clone.Parent = workspace
	humanoid.Health = 0
	
	for _, part : Instance in clone:GetDescendants() do
		if(part:IsA("BasePart")) then
			part.Anchored = false
			
			if(part ~= clone.HumanoidRootPart) then
				part.CanCollide = true
			end
		end
	end
	
	for _, joint in clone:GetDescendants() do
		if joint:IsA("AnimationConstraint") then
			joint.Enabled = false
		elseif joint:IsA("BallSocketConstraint") then
			joint.MaxFrictionTorque = 1
		end
	end

	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Dead)
end
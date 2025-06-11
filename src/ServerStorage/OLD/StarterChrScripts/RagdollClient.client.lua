local Character = script.Parent
local hum = Character:WaitForChild("Humanoid")
local Rep = game:GetService("ReplicatedStorage")
local Modules = Rep:WaitForChild("Modules")
local helperRagdollModule = require(Modules:WaitForChild("HelperRagdoll"))
local remotes = Rep:WaitForChild("Remotes")
local ragdollEvent = remotes:WaitForChild("Ragdolled")
local diedEvent = remotes:WaitForChild("Died")

ragdollEvent.OnClientEvent:Connect(function(Value, Vector)
	if Value then
		helperRagdollModule:PushRagdoll(Character, Vector)
	elseif not Value then
		
		if hum.RigType == Enum.RigType.R15 then
			Character.Head.CanCollide = false
			Character.HumanoidRootPart.CanCollide = true
		end
		
		hum:ChangeState(Enum.HumanoidStateType.GettingUp, true)
	end
end)

hum.Died:Connect(function()
	diedEvent:FireServer()
end)
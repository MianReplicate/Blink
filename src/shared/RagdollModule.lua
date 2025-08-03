local Ragdolls = {}

local Ragdoll = {}
Ragdoll.__index = Ragdoll

local function NewRagdollAttachment(parent, cframeValue)
	local attachment = Instance.new("Attachment");
	attachment.Name = "RagdollAttachment";
	attachment.Parent = parent
	attachment.CFrame = cframeValue
	
	return attachment;
end

local function NewBallSocketConstraint(parent,attachment0,attachment1)
	local socket = Instance.new("BallSocketConstraint");
	socket.Name = "RagdollBallSocketConstraint";
	socket.Parent = parent;
	socket.Attachment0 = attachment0;
	socket.Attachment1 = attachment1;
	socket.LimitsEnabled = true
	socket.TwistLimitsEnabled = true
	
	return socket
end

function Ragdoll.IsARagdoll(char)
	return Ragdolls[char]
end

function Ragdoll.new(char, ragdollondeath)
	local self = setmetatable({}, Ragdoll)

	self.char = char
	self.Ragdolled = false
	self.RagdollOnDeath = ragdollondeath
	
	local hum = self.char:WaitForChild("Humanoid")

	if hum.RigType == Enum.HumanoidRigType.R15 then
		char.Head.CanCollide = true
		char.HumanoidRootPart.CanCollide = false
	end
	
    local tool = self.char:FindFirstChildWhichIsA("Tool")
    for i, part in ipairs(self.char:GetDescendants()) do
        if part:IsA("Part") then
            if tool then
                if not part:IsDescendantOf(tool) then
                    part:SetNetworkOwner(nil)
                end
            else
                part:SetNetworkOwner(nil)
            end
        end
    end
	
	hum.BreakJointsOnDeath = false
	Ragdolls[self.char] = self
	
	if self.RagdollOnDeath then
		char.Humanoid.Died:Connect(function()
			self:ragdoll(-char.HumanoidRootPart.CFrame.LookVector)
		end)
	end
	
	return self
end

function Ragdoll:ragdoll(Vector)
	if not self.Ragdolled then
		self.Ragdolled = true
		local ignoreList = {"HumanoidRootPart", "LowerTorso"}
		for index,joint in pairs(self.char:GetDescendants()) do
			if joint:IsA("Motor6D") and not table.find(ignoreList, joint.Parent.Name) then
				local a1 = NewRagdollAttachment(joint.Part0, joint.C0);
				local a2 = NewRagdollAttachment(joint.Part1, joint.C1);
				local socket = NewBallSocketConstraint(joint.Parent, a1, a2);

				joint.Enabled = false
			end
		end
        Ragdoll:PushRagdoll(self.char, Vector)
	end
	return self.Ragdolled
end

function Ragdoll:unragdoll()
	if self.RagdollOnDeath then
		if self.char.Humanoid.Health <= 0 then
			return
		end
	end
	
	if self.Ragdolled then
		for index,desc in pairs(self.char:GetDescendants()) do
			if desc.Name == "RagdollBallSocketConstraint" or desc.Name == "RagdollAttachment" then
				desc:Destroy()
			elseif desc:IsA("Motor6D") then
				desc.Enabled = true
			end
		end
		
		self.char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		self.Ragdolled = false
	end

	return self.Ragdolled
end


function Ragdoll:PushRagdoll(char, Vector)
	char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

	repeat
		task.wait()
	until not char.Humanoid:GetStateEnabled(Enum.HumanoidStateType.GettingUp)
	
	if not char.Humanoid:GetStateEnabled(Enum.HumanoidStateType.Dead) then
		char.Humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	end
	
	Vector = Vector or char.HumanoidRootPart.CFrame.LookVector
	local velocity = 100 --desired velocity in studs/sec
	local lookDirection = Vector --unit vector of the direction towards the target
	local velocityVector = lookDirection * velocity --create a velocity vector that has a direction

	char.HumanoidRootPart:ApplyImpulse(velocityVector)
end


return Ragdoll

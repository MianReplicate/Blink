---@module Easy Ragdoll by theonlyflare

--- Services ---
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--- Module ---
local RagdollModule = {}

--- Constants ---
-- Names of instances created by the ragdoll system, used for cleanup.
local RAGDOLL_INSTANCE_NAMES = {
	["RagdollAttachment"] = true,
	["RagdollConstraint"] = true,
	["ColliderPart"] = true, -- Keep this for cleanup in case old ragdolls had them
}

--- Helper Functions ---

--[[
	@param character: Model -- The character model to ragdoll.
	@param humanoid: Humanoid -- The humanoid object within the character.
	@brief Converts Motor6D joints into BallSocketConstraints to enable ragdolling.
	This process involves disabling existing Motor6D joints and replacing them
	with physics-based constraints.
]]
local function replaceJoints(character: Model, humanoid: Humanoid)
	-- Necessary for Ragdolling to function properly
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = true

	-- Disable the 'Animate' script to stop character animations
	local animateScript = character:FindFirstChild("Animate")
	if animateScript and animateScript:IsA("LocalScript") then
		animateScript.Enabled = false
	end

	-- Stop all playing animations on the humanoid's animator
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop()
		end
	end

	-- Iterate through all descendants to find Motor6D joints
	for _, motor: Motor6D in pairs(character:GetDescendants()) do
		if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then -- Ensure parts exist for the Motor6D
			motor.Enabled = false -- Disable the Motor6D to allow physics to take over

			-- Create attachments for the BallSocketConstraint
			local attachment0 = Instance.new("Attachment")
			local attachment1 = Instance.new("Attachment")

			-- Set Attachment CFrames based on Motor6D's C0 and C1
			attachment0.CFrame = motor.C0
			attachment1.CFrame = motor.C1

			attachment0.Name = "RagdollAttachment"
			attachment1.Name = "RagdollAttachment"

			-- Create the BallSocketConstraint
			local ballSocketConstraint = Instance.new("BallSocketConstraint")
			ballSocketConstraint.Attachment0 = attachment0
			ballSocketConstraint.Attachment1 = attachment1
			ballSocketConstraint.Name = "RagdollConstraint"

			-- Generic BallSocketConstraint properties. These can be fine-tuned
			-- for specific joints for more realistic ragdoll behavior.
			ballSocketConstraint.Radius = 0.15
			ballSocketConstraint.LimitsEnabled = true
			ballSocketConstraint.TwistLimitsEnabled = true -- Allow some twist, but with limits
			ballSocketConstraint.MaxFrictionTorque = 0 -- No friction at the joint
			ballSocketConstraint.Restitution = 0 -- No bounce at the joint
			ballSocketConstraint.UpperAngle = 90
			ballSocketConstraint.TwistLowerAngle = -45
			ballSocketConstraint.TwistUpperAngle = 45

			-- Apply specific overrides for certain joints for better control
			if motor.Name:find("Neck") then
				ballSocketConstraint.UpperAngle = 45
				ballSocketConstraint.TwistLowerAngle = -70
				ballSocketConstraint.TwistUpperAngle = 70
			elseif motor.Name:find("Hip") then
				ballSocketConstraint.UpperAngle = 60
				ballSocketConstraint.TwistLowerAngle = -30
				ballSocketConstraint.TwistUpperAngle = 30
			elseif motor.Name:find("Shoulder") then
				ballSocketConstraint.UpperAngle = 75
				ballSocketConstraint.TwistLowerAngle = -60
				ballSocketConstraint.TwistUpperAngle = 60
			end

			-- Parent the attachments and constraint
			attachment0.Parent = motor.Part0
			attachment1.Parent = motor.Part1
			ballSocketConstraint.Parent = motor.Parent
		end
	end

	humanoid.AutoRotate = false -- Disabling AutoRotate prevents the Character rotating in first person or Shift-Lock
	character:SetAttribute("LastRag", tick()) -- Used for anti-cheats to prevent flying Ragdolls from getting flagged
end

--[[
	@param character: Model -- The character model to unragdoll.
	@param humanoid: Humanoid -- The humanoid object within the character.
	@brief Destroys all Ragdoll-related instances (attachments, constraints, colliders)
	and re-enables the original Motor6D's to restore normal character animation.
]]
local function resetJoints(character: Model, humanoid: Humanoid)
	-- Do not unragdoll if the humanoid is dead
	if humanoid.Health < 1 then return end

	for _, instance in pairs(character:GetDescendants()) do
		-- Destroy instances created by the ragdoll system
		if RAGDOLL_INSTANCE_NAMES[instance.Name] then
			instance:Destroy()
		end

		-- Re-enable original Motor6D joints
		if instance:IsA("Motor6D") then
			instance.Enabled = true
		end
	end

	humanoid.AutoRotate = true

	-- Re-enable the 'Animate' script
	local animateScript = character:FindFirstChild("Animate")
	if animateScript and animateScript:IsA("LocalScript") then
		animateScript.Enabled = true
	end
end

--[[
	@param character: Model -- The character model to push.
	@param magnitude: number -- The magnitude of the push to apply.
	@brief Applies an impulse to the character's HumanoidRootPart or Torso.
]]
local function applyPush(character: Model, magnitude: number)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		-- Apply impulse in the opposite direction of the character's forward vector
		rootPart:ApplyImpulse(rootPart.CFrame.LookVector * -magnitude)
	end
end

--- Module Functions ---

--[[
	@param character: Model -- The character model to apply or remove ragdoll from.
	@param value: boolean -- True to ragdoll, false to unragdoll.
	@param applyPushOnRagdoll: boolean? -- Optional: Whether to apply a push when ragdolling. Defaults to false.
	@param pushMagnitude: number? -- Optional: The magnitude of the push if applyPushOnRagdoll is true. Defaults to 100.
	@brief Toggles the ragdoll state of the given character, with an option to apply an extra push.
]]
function RagdollModule.SetRagdoll(character: Model, value: boolean, applyPushOnRagdoll: boolean?, pushMagnitude: number?)
	-- Validate inputs
	if not character then
		warn("RagdollModule.SetRagdoll: No character provided.")
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("RagdollModule.SetRagdoll: Character does not have a Humanoid.")
		return
	end

	-- Set default optional parameters
	applyPushOnRagdoll = applyPushOnRagdoll or false
	pushMagnitude = pushMagnitude or 100

	if value then -- Ragdoll the character
		replaceJoints(character, humanoid)
		
		--> Check to see if the module is being called from client/server
		if RunService:IsClient() then
			humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			
		elseif RunService:IsServer() then
			character.PrimaryPart:SetNetworkOwner(nil)
			
			humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		end

		-- Apply push only if explicitly requested
		if applyPushOnRagdoll then
			applyPush(character, pushMagnitude)
		end
	else -- Unragdoll the character
		resetJoints(character, humanoid)
		
		if RunService:IsClient() then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			
		elseif RunService:IsServer() then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			
			-- Fix network ownership for players
			local player: Player? = Players:GetPlayerFromCharacter(character)
			if player then
				character.PrimaryPart:SetNetworkOwner(player)
			end
		end
	end
end

-- Return the module
return RagdollModule
----------------------
-- Name: Roles
-- Authors: MianReplicate
-- Created: 7/11/2024
----------------------
local Data = require(script.Parent)

-- Some ragdoll functions for Survivors
function NewRagdollAttachment(parent, cframeValue)
	local attachment = Instance.new("Attachment");
	attachment.Name = "RagdollAttachment";
	attachment.Parent = parent
	attachment.CFrame = cframeValue

	return attachment;
end

function NewBallSocketConstraint(parent,attachment0,attachment1)
	local socket = Instance.new("BallSocketConstraint");
	socket.Name = "RagdollBallSocketConstraint";
	socket.Parent = parent;
	socket.Attachment0 = attachment0;
	socket.Attachment1 = attachment1;
	socket.LimitsEnabled = true
	socket.TwistLimitsEnabled = true

	return socket
end

local datainfo : Data.DataInfo = {
	subTypes = {
		Common = {
			init = function(data)
				local character = data:getValue("identifier")
				for _, addition : Instance in script[data:getValue("datatypeinfo").subtype]:GetChildren() do
					local parent = (addition:GetAttribute("Parent") and character:FindFirstChild(addition:GetAttribute("Parent"))) or character
					addition:Clone().Parent = parent
				end

				data:setValue("died", function()
					print("im here to tell you that ur subtype role should have a died function lol")
				end)
			end,
			Survivor = {
				init = function(data)
					data:setMultipleValues({
						blinkMeter = {
							maxValue = 100,
							value = 100
						},
						blinkDrainAmount = 10,
						blinkIncreaseAmount = {
							minValue = 0,
							value = 15
						},
						blinkDrainTime = {
							minValue = 0.2,
							value = 1
						},
						sprintMeter = {
							maxValue = 100,
							value = 100
						},
						blinking = false,
						blink = function()
							if data:getValue("blinking") then return end
							local oldTexture = data:getValue("identifier").Head.face.Texture
							data:setValue("blinking", true, {data:getValue("player")})
							data:activateFunction("stopBlinkDrain")
							print("Blinking!")
							data:getValue("identifier").Head.face.Texture = "http://www.roblox.com/asset/?id=15324447"
							task.wait(0.3)
							data:setMultipleValues({
								blinkMeter = {
									maxValue = 100,
								},
								blinkDrainAmount = 10,
								blinkIncreaseAmount = {
									minValue = 0,
									value = 15
								},
								blinkDrainTime = {
									minValue = 0.2,
									value = 1
								},
							})
							data:getValue("identifier").Head.face.Texture = oldTexture
							data:setValue("value", 100, {data:getValue("player")}, "blinkMeter")
							data:activateFunction("startBlinkDrain")
							data:setValue("blinking", false, {data:getValue("player")})
						end,
						startBlinkDrain = function()
							local drainThread = coroutine.create(function()
								local success = data:safelyRunFunc(function()
									while data:getValue("value", "blinkMeter") > 0 do
										task.wait(data:getValue("value", "blinkDrainTime"))
										data:setValue("value", math.max(data:getValue("value", "blinkMeter") - data:getValue("blinkDrainAmount"), 0), {data:getValue("player")}, "blinkMeter")
										if data:getValue("value", "blinkMeter") <= 0 then
											data:activateFunction("blink", true) -- Have to run in a separate thread otherwise it errors
										end
									end
								end)
								if not success then
									coroutine.yield()
								end
							end)
							data:setValue("blinkDrainingThread", drainThread)
							coroutine.resume(data:getValue("blinkDrainingThread"))
						end,
						stopBlinkDrain = function()
							local success
							repeat
								success = pcall(function()
									task.cancel(data:getValue("blinkDrainingThread"))
								end)
								task.wait()
							until success
							data:setValue("blinkDrainingThread", nil)
						end,
						keepEyesOpen = function()
							if data:getValue("value", "blinkMeter") < data:getValue("maxValue", "blinkMeter") and not data:getValue("blinking") then
								data:setValue("value", math.min(data:getValue("value", "blinkMeter") + data:getValue("value", "blinkIncreaseAmount"), data:getValue("maxValue", "blinkMeter")), {data:getValue("player")}, "blinkMeter")
								data:setValue("value", math.max(data:getValue("value", "blinkIncreaseAmount") - 0.5, data:getValue("minValue", "blinkIncreaseAmount")), nil, "blinkIncreaseAmount")
								data:setValue("value", math.max(data:getValue("value", "blinkDrainTime") - 0.02, data:getValue("minValue", "blinkDrainTime")), nil, "blinkDrainTime")
							end
						end,
						startSprint = function()

						end,
						stopSprint = function()

						end,
						died = function()
							data:sendPacket({data:getValue("player")}, shared.Utils.retrieveEnum("PacketTypes.RoleKilled"))
							local character = data:getValue("identifier")
							local newCharacter = character:Clone()
							character:Destroy()

							local snapSoundCount = 4
							local random = math.random(1, snapSoundCount)
							newCharacter.HumanoidRootPart[`Snap{random}`]:Play()

							local ignoreList = {"HumanoidRootPart", "LowerTorso"}
							for index,joint in pairs(newCharacter:GetDescendants()) do
								if joint:IsA("Motor6D") and not table.find(ignoreList, joint.Parent.Name) then
									local a1 = NewRagdollAttachment(joint.Part0, joint.C0);
									local a2 = NewRagdollAttachment(joint.Part1, joint.C1);
									local socket = NewBallSocketConstraint(joint.Parent, a1, a2);

									joint.Enabled = false
								end
							end
							newCharacter.Parent = workspace

							newCharacter.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

							repeat
								task.wait()
							until not newCharacter.Humanoid:GetStateEnabled(Enum.HumanoidStateType.GettingUp)

							if not newCharacter.Humanoid:GetStateEnabled(Enum.HumanoidStateType.Dead) then
								newCharacter.Humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
							end

							local vector = -newCharacter.HumanoidRootPart.CFrame.LookVector
							local velocity = 100 --desired velocity in studs/sec
							local lookDirection = vector --unit vector of the direction towards the target
							local velocityVector = lookDirection * velocity --create a velocity vector that has a direction

							newCharacter.HumanoidRootPart:ApplyImpulse(velocityVector)
							newCharacter.Humanoid.Health = 1
							task.wait(.1)
							newCharacter.Humanoid.Health = 0
						end,
					})
					data:activateFunction("startBlinkDrain")
			--[[
			TODO:
			1. Sprinting
			2. Death screen + Death sound (Death sound should be heard for everyone)
			3. Survivor animations (Walking)
			4. Controls for PC + Mobile
			]]
				end,
			},
			Angel = {
				init = function(data)
					data:setMultipleValues({
						seeingPlayers = {

						},
						useAbility = function(abilityName : string)
							-- TODO: Script this in mind of Angels having multiple abilities: flickering, seeing through walls, etc
						end,
					})

					--[[
					TODO:
					1. Purple Vision (Client-sided purple light that has a bit of range)
					2. Kill players when touched
					3. Freeze when looked at
					4. (Ability) See people through walls
					5. (Ability) Flicker
					6. Death (Crumbling sound, random stones spawning around)
					7. Swap Animations When Unfrozen
					8. User-Interface
					9. Controls for PC + Mobile
					]]
				end,
			}
		},
	},
	packetTypes = {
		"RoleChanged",
		"RoleRemoved",
		"RoleKilled",
	},
	settings = {
		replicateType = true,
	}
}

return datainfo
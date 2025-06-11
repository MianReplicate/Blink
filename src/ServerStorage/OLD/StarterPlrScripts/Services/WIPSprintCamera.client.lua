local sensitivity = 0.05 -- How much "inertia" when moving the camera
local deceleration = 2 -- How fast the speed decelerates.

local cam = workspace.Camera

local rotate = Vector3.zero
local max = math.max
local rad = math.pi/180

local mouseMove = Enum.UserInputType.MouseMovement
game:GetService'UserInputService'.InputChanged:Connect(function(input)
	if input.UserInputType == mouseMove then
		rotate -= input.Delta*sensitivity
	end
end)

game:GetService'RunService':BindToRenderStep('InertialCamera',Enum.RenderPriority.Camera.Value-1,function(dt)
	rotate *= 1-dt*deceleration
	cam.CFrame *= CFrame.fromOrientation(rotate.Y*rad,rotate.X*rad,0)
end)
local tweenService = game:GetService("TweenService")

task.wait(1)
for _,gui in pairs(script.Parent:GetDescendants()) do
	if (gui:IsA("ImageButton") or gui:IsA("TextButton")) then
		
		local shadow = gui:FindFirstChild("Shadow")
		local UIStroke = gui:FindFirstChild("UIStroke")
		
		repeat task.wait() until shadow
		
		local isHovering = false
		local sizeX = gui.Size.X.Scale * 1.1
		local sizeY = gui.Size.Y.Scale * 1.1
		local sizeXsmall = gui.Size.X.Scale / 1.1
		local sizeYsmall = gui.Size.Y.Scale / 1.1
		local sizeXbig = gui.Size.X.Scale
		local sizeYbig = gui.Size.Y.Scale
		
		local SsizeX = shadow.Size.X.Scale * 1.01
		local SsizeY = shadow.Size.Y.Scale * 1.05
		local SsizeXbig = shadow.Size.X.Scale
		local SsizeYbig = shadow.Size.Y.Scale

		gui.MouseEnter:Connect(function()
			isHovering = true
			gui:TweenSize(UDim2.new(sizeX,0,sizeY, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quint, 0.2, true)
			UIStroke.Thickness = 6
			UIStroke.Color = Color3.fromRGB(218, 153, 0)
			shadow:TweenSize(UDim2.new(SsizeX,0,SsizeY, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quint, 0.2, true)
		end)

		gui.MouseLeave:Connect(function()
			isHovering = false
			gui:TweenSize(UDim2.new(sizeXbig, 0, sizeYbig, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quint, 0.2, true) 
			UIStroke.Thickness = 4
			UIStroke.Color = Color3.fromRGB(255, 209, 116)
			shadow:TweenSize(UDim2.new(SsizeXbig, 0, SsizeYbig, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quint, 0.2, true) 
		end)

		gui.MouseButton1Down:Connect(function()
			gui:TweenSize(UDim2.new(sizeXsmall, 0, sizeYsmall, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quint, 0.1, true)
		end)

		gui.MouseButton1Up:Connect(function()
		if not isHovering then
			gui:TweenSize(UDim2.new(sizeXsmall, 0, sizeYsmall, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quint, 0.1, true)
		else
			gui:TweenSize(UDim2.new(sizeX,0,sizeY, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quint, 0.1, true)
		end
		end)
	end
end


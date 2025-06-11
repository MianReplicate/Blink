script.Parent.MouseButton1Click:Connect(function()
	script.Parent.Parent.Parent.AccessibilityFrame.Visible = not script.Parent.Parent.Parent.AccessibilityFrame.Visible
	if script.Parent.Parent.Parent.AccessibilityFrame.Visible then
		script.Parent.Parent.Parent.VideoFrame.Visible = false
		script.Parent.Parent.Parent.AudioFrame.Visible = false
	end
end)
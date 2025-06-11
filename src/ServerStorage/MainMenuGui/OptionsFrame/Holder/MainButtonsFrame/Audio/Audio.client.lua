script.Parent.MouseButton1Click:Connect(function()
	script.Parent.Parent.Parent.AudioFrame.Visible = not script.Parent.Parent.Parent.AudioFrame.Visible
	if script.Parent.Parent.Parent.AudioFrame.Visible then
		script.Parent.Parent.Parent.VideoFrame.Visible = false
		script.Parent.Parent.Parent.AccessibilityFrame.Visible = false
	end
end)
script.Parent.MouseButton1Click:Connect(function()
	script.Parent.Parent.Parent.VideoFrame.Visible = not script.Parent.Parent.Parent.VideoFrame.Visible
	if script.Parent.Parent.Parent.VideoFrame.Visible then
		script.Parent.Parent.Parent.AccessibilityFrame.Visible = false
		script.Parent.Parent.Parent.AudioFrame.Visible = false
	end
end)
script.Parent.MouseButton1Click:Connect(function()
	script.Parent.Parent.Parent.Credits.Visible = not script.Parent.Parent.Parent.Credits.Visible
	if script.Parent.Parent.Parent.Credits.Visible then
		script.Parent.Parent.Parent.Changelogs.Visible = false
	end
end)
script.Parent.MouseButton1Click:Connect(function()
	script.Parent.Parent.Parent.Changelogs.Visible = not script.Parent.Parent.Parent.Changelogs.Visible
	if script.Parent.Parent.Parent.Changelogs.Visible then
		script.Parent.Parent.Parent.Credits.Visible = false
	end
end)
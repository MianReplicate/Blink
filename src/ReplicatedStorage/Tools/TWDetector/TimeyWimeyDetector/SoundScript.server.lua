script.Parent.Equipped:Connect(function()
	wait(0.1)
	script.Parent.SpinPart.TWEquipSound:Play()
	wait(script.Parent.SpinPart.TWEquipSound.TimeLength)
	script.Parent.SpinPart.TWIdleSound:Play()

end)

script.Parent.Unequipped:Connect(function()
	script.Parent.SpinPart.TWUnEquipSound:Play()
	wait(0.2)	
	script.Parent.SpinPart.TWIdleSound:Stop()
	script.Parent.SpinPart.TWEquipSound:Stop()


end)








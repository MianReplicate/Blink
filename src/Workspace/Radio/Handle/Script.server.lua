local BoomboxMesh = script.Parent
local ClickDetector = BoomboxMesh.ClickDetector
local Playing = false
local Radio = BoomboxMesh.Radio
local SongsFolder = BoomboxMesh.Songs
local Effects = BoomboxMesh.ParticleEmitter
local TurnOn = BoomboxMesh.radioOn
local Toggle = BoomboxMesh.Toggle



function GetRandomSong()
	local Playlist = SongsFolder:GetChildren()
	local ChosenSong = Playlist[math.random(1, #Playlist)]
	
	return ChosenSong
end


local Unit = BoomboxMesh.Size.X*BoomboxMesh.Size.Y*BoomboxMesh.Size.Z + 100
function Bounce(Strength)
	local Force = Strength*Unit
	BoomboxMesh:ApplyImpulse(Vector3.new(math.random(-Force*.5, Force*.5), math.random(-Force*1.5, Force*1.5), math.random(-Force*.5, Force*.5)))
end



ClickDetector.MouseClick:Connect(function(Player)
	Playing = not Playing
	Toggle:Play()
	
	if Playing then
		TurnOn:Play()
		local song = GetRandomSong()
		Radio.SoundId = song.SoundId
		Radio.PlaybackSpeed = song.PlaybackSpeed
		
		Bounce(math.random(10,25))
		print("Boombox, Now playing:", song.Name)
	end
	
	Radio.Playing = Playing
	Effects.Enabled = Playing
end)


local Tool = BoomboxMesh.Parent
Tool.AncestryChanged:Connect(function()
	if Tool.Parent == workspace then
		BoomboxMesh.Parent = workspace
		BoomboxMesh.Name = "Radio"
		task.wait()
		Tool:Destroy()
	end
end)
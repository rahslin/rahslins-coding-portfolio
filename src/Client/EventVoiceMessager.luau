--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Source = ReplicatedStorage:WaitForChild("Source")
local Remotes = Source:WaitForChild("AdminPanel"):WaitForChild("Remotes")

Remotes.EventVoice.OnClientEvent:Connect(function(soundId: string)
	local sound = Instance.new("Sound")
	sound.SoundId = `rbxassetid://{soundId}`
	sound.Volume = 1
	sound.Parent = workspace
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 30)
end)
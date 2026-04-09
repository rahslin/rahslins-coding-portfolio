--!strict
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Source = ReplicatedStorage:WaitForChild("Source")
local Remotes = Source:WaitForChild("AdminPanel"):WaitForChild("Remotes")

Remotes.TrollBlind.OnClientEvent:Connect(function(duration: number)
	local blur = Instance.new("BlurEffect")
	blur.Size = 56
	blur.Parent = Lighting
	task.delay(duration, function()
		blur:Destroy()
	end)
end)
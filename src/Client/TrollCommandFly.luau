--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = assert(Players.LocalPlayer)
local Source = ReplicatedStorage:WaitForChild("Source")
local Remotes = Source:WaitForChild("AdminPanel"):WaitForChild("Remotes")

Remotes.TrollFly.OnClientEvent:Connect(function(duration: number)
	local character = Player.Character or Player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not humanoid or not rootPart then return end

	humanoid.PlatformStand = true

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVelocity.Parent = rootPart

	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	bodyGyro.D = 100
	bodyGyro.Parent = rootPart

	local camera = workspace.CurrentCamera
	local connection = RunService.Heartbeat:Connect(function()
		local moveDir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveDir += camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveDir -= camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveDir -= camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveDir += camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			moveDir += Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			moveDir -= Vector3.new(0, 1, 0)
		end
		bodyVelocity.Velocity = moveDir.Magnitude > 0 and moveDir.Unit * 60 or Vector3.zero
		bodyGyro.CFrame = camera.CFrame
	end)

	task.delay(duration, function()
		connection:Disconnect()
		bodyVelocity:Destroy()
		bodyGyro:Destroy()
		if humanoid then
			humanoid.PlatformStand = false
		end
	end)
end)
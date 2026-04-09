local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local camPart = workspace:WaitForChild("CamPart")

pcall(function() ReplicatedFirst:RemoveDefaultLoadingScreen() end)

if player.Name == "keeptheluck" then return end

camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = camPart.CFrame

local originallyEnabled = {}

for _, g in ipairs(playerGui:GetChildren()) do
	if g:IsA("ScreenGui") or g:IsA("BillboardGui") or g:IsA("SurfaceGui") then
		originallyEnabled[g.Name] = g.Enabled
		if g.Name ~= "CustomLoadingScreen" then g.Enabled = false end
	end
end

local guiConnection = playerGui.ChildAdded:Connect(function(g)
	if g.Name ~= "CustomLoadingScreen" and (g:IsA("ScreenGui") or g:IsA("BillboardGui") or g:IsA("SurfaceGui")) then
		originallyEnabled[g.Name] = g.Enabled
		g.Enabled = false
	end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "CustomLoadingScreen"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = playerGui

local blur = Instance.new("BlurEffect")
blur.Size = 24
blur.Parent = game:GetService("Lighting")

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
background.BorderSizePixel = 0
background.BackgroundTransparency = 0.8
background.Parent = gui

local BASE_SIZE = 770
local BREATH_DELTA = 300
local BREATH_PERIOD = 3.2
local MAX_LOAD_TIME = 7
local BATCH_SIZE = 10

local image = Instance.new("ImageLabel")
image.AnchorPoint = Vector2.new(0.5, 0.5)
image.Position = UDim2.fromScale(0.49, 0.42)
image.Size = UDim2.fromOffset(BASE_SIZE, BASE_SIZE)
image.BackgroundTransparency = 1
image.ImageTransparency = 1
image.Image = "rbxassetid://139270972371368"
image.ScaleType = Enum.ScaleType.Fit
image.Parent = background

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.63)
title.Size = UDim2.fromOffset(500, 40)
title.BackgroundTransparency = 1
title.Text = "Loading..."
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.FredokaOne
title.Parent = background

local percentText = Instance.new("TextLabel")
percentText.AnchorPoint = Vector2.new(0.5, 0.5)
percentText.Position = UDim2.fromScale(0.5, 0.69)
percentText.Size = UDim2.fromOffset(200, 30)
percentText.BackgroundTransparency = 1
percentText.Text = "0%"
percentText.TextColor3 = Color3.fromRGB(255, 255, 255)
percentText.TextScaled = true
percentText.Font = Enum.Font.FredokaOne
percentText.Parent = background

local barHolder = Instance.new("Frame")
barHolder.AnchorPoint = Vector2.new(0.5, 0.5)
barHolder.Position = UDim2.fromScale(0.5, 0.77)
barHolder.Size = UDim2.fromOffset(420, 22)
barHolder.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
barHolder.BorderSizePixel = 0
barHolder.Parent = background

local barHolderCorner = Instance.new("UICorner")
barHolderCorner.CornerRadius = UDim.new(1, 0)
barHolderCorner.Parent = barHolder

local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = Color3.fromRGB(85, 255, 0)
barFill.BorderSizePixel = 0
barFill.Parent = barHolder

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(1, 0)
barFillCorner.Parent = barFill

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180)),
})
gradient.Parent = barFill

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 70, 70)
stroke.Thickness = 1.5
stroke.Parent = barHolder

TweenService:Create(image, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	ImageTransparency = 0,
}):Play()

local breathing = true
local breathStartTime = tick()
local currentSize = BASE_SIZE

local breathConnection
breathConnection = RunService.Heartbeat:Connect(function(dt)
	if not breathing then
		breathConnection:Disconnect()
		return
	end
	local t = (tick() - breathStartTime) / BREATH_PERIOD
	local wave = (math.sin(t * math.pi * 2) + 1) / 2
	local targetSize = BASE_SIZE + wave * BREATH_DELTA
	currentSize = currentSize + (targetSize - currentSize) * math.min(dt * 12, 1)
	image.Size = UDim2.fromOffset(currentSize, currentSize)
end)

local currentPercent = 0
local loadingDone = false

task.spawn(function()
	while currentPercent < 90 and not loadingDone do
		task.wait(0.05)
		currentPercent += 1
		TweenService:Create(barFill, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {
			Size = UDim2.fromScale(currentPercent / 100, 1),
		}):Play()
		percentText.Text = currentPercent .. "%"
	end
end)

local assets = {}
for _, obj in ipairs(game:GetDescendants()) do
	if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("ImageLabel")
		or obj:IsA("ImageButton") or obj:IsA("MeshPart")
		or obj:IsA("Sound") or obj:IsA("Animation") then
		table.insert(assets, obj)
	end
end

task.delay(MAX_LOAD_TIME, function()
	loadingDone = true
end)

task.spawn(function()
	local i = 1
	while i <= #assets and not loadingDone do
		local batch = {}
		for j = i, math.min(i + BATCH_SIZE - 1, #assets) do
			table.insert(batch, assets[j])
		end
		pcall(ContentProvider.PreloadAsync, ContentProvider, batch)
		i += BATCH_SIZE
		RunService.RenderStepped:Wait()
	end
	loadingDone = true
end)

while not loadingDone do
	RunService.RenderStepped:Wait()
end

breathing = false
image.Size = UDim2.fromOffset(BASE_SIZE, BASE_SIZE)
title.Text = "Loaded"
percentText.Text = "100%"

TweenService:Create(barFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	Size = UDim2.fromScale(1, 1),
}):Play()

task.wait(0.35)

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local head = character:WaitForChild("Head")

local targetCFrame = CFrame.new(
	head.Position + (head.CFrame.LookVector * -8) + Vector3.new(0, 3, 0),
	head.Position
)

local cameraTween = TweenService:Create(camera, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
	CFrame = targetCFrame,
})
cameraTween:Play()

local fadeInfo = TweenInfo.new(1.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fadeTargets = {
	{ blur,       { Size = 0 } },
	{ background, { BackgroundTransparency = 1 } },
	{ image,      { ImageTransparency = 1 } },
	{ title,      { TextTransparency = 1 } },
	{ percentText,{ TextTransparency = 1 } },
	{ barHolder,  { BackgroundTransparency = 1 } },
	{ barFill,    { BackgroundTransparency = 1 } },
	{ stroke,     { Transparency = 1 } },
}
for _, t in ipairs(fadeTargets) do
	TweenService:Create(t[1], fadeInfo, t[2]):Play()
end

cameraTween.Completed:Wait()

guiConnection:Disconnect()
for _, g in ipairs(playerGui:GetChildren()) do
	if g:IsA("ScreenGui") or g:IsA("BillboardGui") or g:IsA("SurfaceGui") then
		g.Enabled = originallyEnabled[g.Name] ~= nil and originallyEnabled[g.Name] or false
	end
end

camera.CameraType = Enum.CameraType.Custom
camera.CameraSubject = humanoid

blur:Destroy()
gui:Destroy()local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local camPart = workspace:WaitForChild("CamPart")

pcall(function() ReplicatedFirst:RemoveDefaultLoadingScreen() end)

if player.Name == "keeptheluck" then return end

camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = camPart.CFrame

local originallyEnabled = {}

for _, g in ipairs(playerGui:GetChildren()) do
	if g:IsA("ScreenGui") or g:IsA("BillboardGui") or g:IsA("SurfaceGui") then
		originallyEnabled[g.Name] = g.Enabled
		if g.Name ~= "CustomLoadingScreen" then g.Enabled = false end
	end
end

local guiConnection = playerGui.ChildAdded:Connect(function(g)
	if g.Name ~= "CustomLoadingScreen" and (g:IsA("ScreenGui") or g:IsA("BillboardGui") or g:IsA("SurfaceGui")) then
		originallyEnabled[g.Name] = g.Enabled
		g.Enabled = false
	end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "CustomLoadingScreen"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = playerGui

local blur = Instance.new("BlurEffect")
blur.Size = 24
blur.Parent = game:GetService("Lighting")

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
background.BorderSizePixel = 0
background.BackgroundTransparency = 0.8
background.Parent = gui

local BASE_SIZE = 770
local BREATH_DELTA = 300
local BREATH_PERIOD = 3.2
local MAX_LOAD_TIME = 7
local BATCH_SIZE = 10

local image = Instance.new("ImageLabel")
image.AnchorPoint = Vector2.new(0.5, 0.5)
image.Position = UDim2.fromScale(0.49, 0.42)
image.Size = UDim2.fromOffset(BASE_SIZE, BASE_SIZE)
image.BackgroundTransparency = 1
image.ImageTransparency = 1
image.Image = "rbxassetid://139270972371368"
image.ScaleType = Enum.ScaleType.Fit
image.Parent = background

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.63)
title.Size = UDim2.fromOffset(500, 40)
title.BackgroundTransparency = 1
title.Text = "Loading..."
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.FredokaOne
title.Parent = background

local percentText = Instance.new("TextLabel")
percentText.AnchorPoint = Vector2.new(0.5, 0.5)
percentText.Position = UDim2.fromScale(0.5, 0.69)
percentText.Size = UDim2.fromOffset(200, 30)
percentText.BackgroundTransparency = 1
percentText.Text = "0%"
percentText.TextColor3 = Color3.fromRGB(255, 255, 255)
percentText.TextScaled = true
percentText.Font = Enum.Font.FredokaOne
percentText.Parent = background

local barHolder = Instance.new("Frame")
barHolder.AnchorPoint = Vector2.new(0.5, 0.5)
barHolder.Position = UDim2.fromScale(0.5, 0.77)
barHolder.Size = UDim2.fromOffset(420, 22)
barHolder.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
barHolder.BorderSizePixel = 0
barHolder.Parent = background

local barHolderCorner = Instance.new("UICorner")
barHolderCorner.CornerRadius = UDim.new(1, 0)
barHolderCorner.Parent = barHolder

local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = Color3.fromRGB(85, 255, 0)
barFill.BorderSizePixel = 0
barFill.Parent = barHolder

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(1, 0)
barFillCorner.Parent = barFill

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180)),
})
gradient.Parent = barFill

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 70, 70)
stroke.Thickness = 1.5
stroke.Parent = barHolder

TweenService:Create(image, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	ImageTransparency = 0,
}):Play()

local breathing = true
local breathStartTime = tick()
local currentSize = BASE_SIZE

local breathConnection
breathConnection = RunService.Heartbeat:Connect(function(dt)
	if not breathing then
		breathConnection:Disconnect()
		return
	end
	local t = (tick() - breathStartTime) / BREATH_PERIOD
	local wave = (math.sin(t * math.pi * 2) + 1) / 2
	local targetSize = BASE_SIZE + wave * BREATH_DELTA
	currentSize = currentSize + (targetSize - currentSize) * math.min(dt * 12, 1)
	image.Size = UDim2.fromOffset(currentSize, currentSize)
end)

local currentPercent = 0
local loadingDone = false

task.spawn(function()
	while currentPercent < 90 and not loadingDone do
		task.wait(0.05)
		currentPercent += 1
		TweenService:Create(barFill, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {
			Size = UDim2.fromScale(currentPercent / 100, 1),
		}):Play()
		percentText.Text = currentPercent .. "%"
	end
end)

local assets = {}
for _, obj in ipairs(game:GetDescendants()) do
	if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("ImageLabel")
		or obj:IsA("ImageButton") or obj:IsA("MeshPart")
		or obj:IsA("Sound") or obj:IsA("Animation") then
		table.insert(assets, obj)
	end
end

task.delay(MAX_LOAD_TIME, function()
	loadingDone = true
end)

task.spawn(function()
	local i = 1
	while i <= #assets and not loadingDone do
		local batch = {}
		for j = i, math.min(i + BATCH_SIZE - 1, #assets) do
			table.insert(batch, assets[j])
		end
		pcall(ContentProvider.PreloadAsync, ContentProvider, batch)
		i += BATCH_SIZE
		RunService.RenderStepped:Wait()
	end
	loadingDone = true
end)

while not loadingDone do
	RunService.RenderStepped:Wait()
end

breathing = false
image.Size = UDim2.fromOffset(BASE_SIZE, BASE_SIZE)
title.Text = "Loaded"
percentText.Text = "100%"

TweenService:Create(barFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	Size = UDim2.fromScale(1, 1),
}):Play()

task.wait(0.35)

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local head = character:WaitForChild("Head")

local targetCFrame = CFrame.new(
	head.Position + (head.CFrame.LookVector * -8) + Vector3.new(0, 3, 0),
	head.Position
)

local cameraTween = TweenService:Create(camera, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
	CFrame = targetCFrame,
})
cameraTween:Play()

local fadeInfo = TweenInfo.new(1.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fadeTargets = {
	{ blur,       { Size = 0 } },
	{ background, { BackgroundTransparency = 1 } },
	{ image,      { ImageTransparency = 1 } },
	{ title,      { TextTransparency = 1 } },
	{ percentText,{ TextTransparency = 1 } },
	{ barHolder,  { BackgroundTransparency = 1 } },
	{ barFill,    { BackgroundTransparency = 1 } },
	{ stroke,     { Transparency = 1 } },
}
for _, t in ipairs(fadeTargets) do
	TweenService:Create(t[1], fadeInfo, t[2]):Play()
end

cameraTween.Completed:Wait()

guiConnection:Disconnect()
for _, g in ipairs(playerGui:GetChildren()) do
	if g:IsA("ScreenGui") or g:IsA("BillboardGui") or g:IsA("SurfaceGui") then
		g.Enabled = originallyEnabled[g.Name] ~= nil and originallyEnabled[g.Name] or false
	end
end

camera.CameraType = Enum.CameraType.Custom
camera.CameraSubject = humanoid

blur:Destroy()
gui:Destroy()
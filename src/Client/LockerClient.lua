local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local SoundService      = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remoteFolder     = ReplicatedStorage:WaitForChild("LockerRemotes")
local equipHatRemote   = remoteFolder:WaitForChild("EquipHat")
local equipShirtRemote = remoteFolder:WaitForChild("EquipShirt")
local equipPantsRemote = remoteFolder:WaitForChild("EquipPants")
local equipVestRemote  = remoteFolder:WaitForChild("EquipVest")
local getItemsRemote   = remoteFolder:WaitForChild("GetItems")
local openLockerRemote = remoteFolder:WaitForChild("OpenLocker")

local COLORS = {
	bg_dark        = Color3.fromRGB(18,  18,  22),
	frame          = Color3.fromRGB(28,  28,  34),
	accent         = Color3.fromRGB(85,  150, 255),
	accent_active  = Color3.fromRGB(110, 170, 255),
	accent_hover   = Color3.fromRGB(100, 160, 245),
	button_dark    = Color3.fromRGB(38,  38,  46),
	button_hover   = Color3.fromRGB(50,  50,  60),
	text_primary   = Color3.fromRGB(235, 235, 245),
	text_secondary = Color3.fromRGB(170, 170, 190),
	green_success  = Color3.fromRGB(60,  200, 100),
	red_close      = Color3.fromRGB(220, 70,  80),
	red_close_hover = Color3.fromRGB(240, 90, 100),
}

local TWEEN = {
	fast   = TweenInfo.new(0.22, Enum.EasingStyle.Sine,  Enum.EasingDirection.Out),
	medium = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	slow   = TweenInfo.new(0.48, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
}

local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://876939830"
clickSound.Volume = 0.35
clickSound.Parent = SoundService

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LockerGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.48, 0, 0.68, 0)
mainFrame.Position = UDim2.new(0.26, 0, 0.16, 0)
mainFrame.BackgroundColor3 = COLORS.frame
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Visible = false
mainFrame.Parent = screenGui

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 14)
	corner.Parent = parent
	return corner
end

addCorner(mainFrame, 14)

local stroke = Instance.new("UIStroke")
stroke.Transparency = 0.78
stroke.Color = Color3.new(0, 0, 0)
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = mainFrame

local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, 0, 0, 54)
titleBar.BackgroundColor3 = COLORS.bg_dark
titleBar.BorderSizePixel = 0
titleBar.Font = Enum.Font.SourceSansBold
titleBar.TextSize = 26
titleBar.TextColor3 = COLORS.text_primary
titleBar.Text = "Wardrobe"
titleBar.TextXAlignment = Enum.TextXAlignment.Center
titleBar.Parent = mainFrame
addCorner(titleBar, 14)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 44, 0, 44)
closeBtn.Position = UDim2.new(1, -54, 0, 6)
closeBtn.BackgroundColor3 = COLORS.red_close
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 28
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "×"
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 12
closeBtn.Parent = mainFrame
addCorner(closeBtn, 10)

local categoryFrame = Instance.new("Frame")
categoryFrame.Size = UDim2.new(1, -20, 0, 110)
categoryFrame.Position = UDim2.new(0, 10, 0, 60)
categoryFrame.BackgroundTransparency = 1
categoryFrame.ZIndex = 10
categoryFrame.Parent = mainFrame

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ItemsScroll"
scroll.Size = UDim2.new(1, -20, 1, -200)
scroll.Position = UDim2.new(0, 10, 0, 175)
scroll.BackgroundColor3 = COLORS.bg_dark
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 90)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ZIndex = 1
scroll.Parent = mainFrame
addCorner(scroll, 10)

local function tween(obj, info, props)
	TweenService:Create(obj, info, props):Play()
end

local function createCategoryButton(label, posX, posY)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.48, 0, 0.45, 0)
	btn.Position = UDim2.new(posX, 0, posY, 0)
	btn.BackgroundColor3 = COLORS.button_dark
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 18
	btn.TextColor3 = COLORS.text_primary
	btn.Text = label
	btn.AutoButtonColor = false
	btn.ZIndex = 11
	btn.Parent = categoryFrame
	addCorner(btn, 10)
	return btn
end

local hatsBtn   = createCategoryButton("Hats",   0,    0)
local shirtsBtn = createCategoryButton("Shirts", 0.52, 0)
local pantsBtn  = createCategoryButton("Pants",  0,    0.55)
local vestsBtn  = createCategoryButton("Vests",  0.52, 0.55)

local currentCategory = "Hats"
local allItems = {}

local categoryButtons = {
	Hats   = hatsBtn,
	Shirts = shirtsBtn,
	Pants  = pantsBtn,
	Vests  = vestsBtn,
}

local categoryRemotes = {
	Hats   = equipHatRemote,
	Shirts = equipShirtRemote,
	Pants  = equipPantsRemote,
	Vests  = equipVestRemote,
}

local function openGUI()
	mainFrame.Position = UDim2.new(0.26, 0, 0.16, -80)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Size = UDim2.new(0.46, 0, 0.65, 0)
	mainFrame.Visible = true

	tween(mainFrame, TWEEN.slow, {
		BackgroundTransparency = 0,
		Position = UDim2.new(0.26, 0, 0.16, 0),
	})
	tween(mainFrame, TWEEN.medium, {
		Size = UDim2.new(0.48, 0, 0.68, 0),
	})
end

local function closeGUI()
	tween(mainFrame, TWEEN.medium, {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.26, 0, 0.16, -100),
	})
	task.delay(TWEEN.medium.Time, function()
		mainFrame.Visible = false
		mainFrame.BackgroundTransparency = 0
		mainFrame.Position = UDim2.new(0.26, 0, 0.16, 0)
		mainFrame.Size = UDim2.new(0.48, 0, 0.68, 0)
	end)
end

local function createItemButton(itemName, index)
	local btn = Instance.new("TextButton")
	btn.Name = itemName
	btn.Size = UDim2.new(1, -12, 0, 48)
	btn.Position = UDim2.new(0, 6, 0, (index - 1) * 54)
	btn.BackgroundColor3 = COLORS.button_dark
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 17
	btn.TextColor3 = COLORS.text_primary
	btn.Text = itemName
	btn.AutoButtonColor = false
	btn.ZIndex = 2
	btn.Parent = scroll
	addCorner(btn, 8)

	tween(btn, TWEEN.medium, { BackgroundTransparency = 0 })

	btn.MouseEnter:Connect(function()
		tween(btn, TWEEN.fast, { BackgroundColor3 = COLORS.button_hover })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, TWEEN.fast, { BackgroundColor3 = COLORS.button_dark })
	end)
	btn.MouseButton1Click:Connect(function()
		clickSound:Play()
		tween(btn, TWEEN.fast, { BackgroundColor3 = COLORS.green_success })
		task.delay(0.25, function()
			tween(btn, TWEEN.fast, { BackgroundColor3 = COLORS.button_dark })
		end)
		local remote = categoryRemotes[currentCategory]
		if remote then remote:FireServer(itemName) end
	end)
end

local function displayItems(category)
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	currentCategory = category
	titleBar.Text = category

	for cat, btn in pairs(categoryButtons) do
		btn.BackgroundColor3 = (cat == category) and COLORS.accent_active or COLORS.button_dark
	end

	local items = allItems[category] or {}

	if #items == 0 then
		local placeholder = Instance.new("TextLabel")
		placeholder.Size = UDim2.new(1, 0, 0, 60)
		placeholder.BackgroundTransparency = 1
		placeholder.Font = Enum.Font.SourceSansBold
		placeholder.TextSize = 16
		placeholder.TextColor3 = COLORS.text_secondary
		placeholder.Text = "No items in this category"
		placeholder.ZIndex = 3
		placeholder.Parent = scroll
		return
	end

	for i, name in ipairs(items) do
		createItemButton(name, i)
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, #items * 54 + 30)
end

local function loadItems()
	local success, data = pcall(function()
		return getItemsRemote:InvokeServer()
	end)
	if success and data then
		allItems = data
		displayItems("Hats")
	else
		warn("Failed to load locker items")
	end
end

local function bindCategoryHover(btn)
	btn.MouseEnter:Connect(function()
		if currentCategory ~= btn.Text then
			tween(btn, TWEEN.fast, { BackgroundColor3 = COLORS.accent_hover })
		end
	end)
	btn.MouseLeave:Connect(function()
		local target = (currentCategory == btn.Text) and COLORS.accent_active or COLORS.button_dark
		tween(btn, TWEEN.fast, { BackgroundColor3 = target })
	end)
	btn.MouseButton1Click:Connect(function()
		clickSound:Play()
	end)
end

local function bindCloseHover(btn)
	btn.MouseEnter:Connect(function()
		tween(btn, TWEEN.fast, { BackgroundColor3 = COLORS.red_close_hover })
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, TWEEN.fast, { BackgroundColor3 = COLORS.red_close })
	end)
	btn.MouseButton1Click:Connect(function()
		clickSound:Play()
	end)
end

bindCategoryHover(hatsBtn)
bindCategoryHover(shirtsBtn)
bindCategoryHover(pantsBtn)
bindCategoryHover(vestsBtn)
bindCloseHover(closeBtn)

hatsBtn.MouseButton1Click:Connect(function()   displayItems("Hats")   end)
shirtsBtn.MouseButton1Click:Connect(function()  displayItems("Shirts") end)
pantsBtn.MouseButton1Click:Connect(function()   displayItems("Pants")  end)
vestsBtn.MouseButton1Click:Connect(function()   displayItems("Vests")  end)
closeBtn.MouseButton1Click:Connect(closeGUI)

openLockerRemote.OnClientEvent:Connect(function()
	loadItems()
	openGUI()
end)

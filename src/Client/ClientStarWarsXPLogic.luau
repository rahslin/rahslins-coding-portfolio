local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player.PlayerGui

local CONFIG = {
	barWidth  = 400,
	barHeight = 30,

	hiddenPosition  = UDim2.new(0.5, 0, 1,  80),
	visiblePosition = UDim2.new(0.5, 0, 1, -60),

	backgroundColor = Color3.fromRGB(30, 30, 35),
	textColor       = Color3.fromRGB(255, 255, 255),

	zoneColors = {
		["1XP"]  = Color3.fromRGB(100, 220, 100),
		["5XP"]  = Color3.fromRGB(80,  150, 255),
		["10XP"] = Color3.fromRGB(255, 90,  90),
	},

	zoneRateLabels = {
		["1XP"]  = "1 XP",
		["5XP"]  = "5 XP",
		["10XP"] = "10 XP",
	},

	slideTime    = 0.45,
	progressTime = 0.25,
}

local RANK_THRESHOLDS = { 0, 100, 250, 500, 1000, 2000, 3500, 5500, 8000, 12000 }

local function createXPBar(guiParent: Instance)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name           = "XPBarGui"
	screenGui.ResetOnSpawn   = false
	screenGui.IgnoreGuiInset = false
	screenGui.Parent         = guiParent

	local mainFrame = Instance.new("Frame")
	mainFrame.Size             = UDim2.new(0, CONFIG.barWidth, 0, CONFIG.barHeight + 50)
	mainFrame.Position         = CONFIG.hiddenPosition
	mainFrame.AnchorPoint      = Vector2.new(0.5, 1)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent           = screenGui

	local zoneLabel = Instance.new("TextLabel")
	zoneLabel.Size                   = UDim2.new(1, 0, 0, 24)
	zoneLabel.Position               = UDim2.new(0, 0, 0, 0)
	zoneLabel.BackgroundTransparency = 1
	zoneLabel.TextColor3             = CONFIG.textColor
	zoneLabel.Font                   = Enum.Font.GothamBold
	zoneLabel.TextSize               = 17
	zoneLabel.TextStrokeTransparency = 0.4
	zoneLabel.Text                   = ""
	zoneLabel.Parent                 = mainFrame

	local bgBar = Instance.new("Frame")
	bgBar.Size             = UDim2.new(1, 0, 0, CONFIG.barHeight)
	bgBar.Position         = UDim2.new(0, 0, 0, 28)
	bgBar.BackgroundColor3 = CONFIG.backgroundColor
	bgBar.BorderSizePixel  = 0
	bgBar.Parent           = mainFrame

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 10)
	bgCorner.Parent       = bgBar

	local bgStroke = Instance.new("UIStroke")
	bgStroke.Color     = Color3.fromRGB(80, 80, 90)
	bgStroke.Thickness = 1.5
	bgStroke.Parent    = bgBar

	local progressBar = Instance.new("Frame")
	progressBar.Size             = UDim2.new(0, 0, 1, 0)
	progressBar.BackgroundColor3 = CONFIG.zoneColors["1XP"]
	progressBar.BorderSizePixel  = 0
	progressBar.ClipsDescendants = true
	progressBar.Parent           = bgBar

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 10)
	progressCorner.Parent       = progressBar

	local shine = Instance.new("Frame")
	shine.Size                   = UDim2.new(1, 0, 0.45, 0)
	shine.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
	shine.BackgroundTransparency = 0.82
	shine.BorderSizePixel        = 0
	shine.Parent                 = progressBar

	local shineCorner = Instance.new("UICorner")
	shineCorner.CornerRadius = UDim.new(0, 10)
	shineCorner.Parent       = shine

	local xpLabel = Instance.new("TextLabel")
	xpLabel.Size                   = UDim2.new(1, 0, 1, 0)
	xpLabel.BackgroundTransparency = 1
	xpLabel.TextColor3             = CONFIG.textColor
	xpLabel.Font                   = Enum.Font.GothamBold
	xpLabel.TextSize               = 14
	xpLabel.TextStrokeTransparency = 0.4
	xpLabel.Text                   = ""
	xpLabel.Parent                 = bgBar

	local inZone        = false
	local activeTween   = nil :: Tween?
	local progressTween = nil :: Tween?

	local function getXPProgress(): (number, number, number, number)
		local xp         = (player:GetAttribute("Points") :: number?) or 0
		local prevThresh = 0
		local nextThresh = RANK_THRESHOLDS[#RANK_THRESHOLDS]

		for i = 1, #RANK_THRESHOLDS - 1 do
			if xp >= RANK_THRESHOLDS[i] and xp < RANK_THRESHOLDS[i + 1] then
				prevThresh = RANK_THRESHOLDS[i]
				nextThresh = RANK_THRESHOLDS[i + 1]
				break
			end
		end

		local range = nextThresh - prevThresh
		local alpha = if range > 0 then math.clamp((xp - prevThresh) / range, 0, 1) else 1

		return xp, prevThresh, nextThresh, alpha
	end

	local function updateBar()
		if not inZone then return end

		local xp, prev, nxt, alpha = getXPProgress()

		if progressTween then progressTween:Cancel() end
		progressTween = TweenService:Create(
			progressBar,
			TweenInfo.new(CONFIG.progressTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.new(alpha, 0, 1, 0) }
		)
		progressTween:Play()

		xpLabel.Text = string.format("%d XP  (%d ? %d)", xp, prev, nxt)
	end

	local function slideTo(targetPos: UDim2)
		if activeTween then
			activeTween:Cancel()
			activeTween = nil
		end

		activeTween = TweenService:Create(
			mainFrame,
			TweenInfo.new(CONFIG.slideTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Position = targetPos }
		)
		activeTween:Play()
	end

	local function showBar(zoneName: string)
		inZone = true

		local color = CONFIG.zoneColors[zoneName] or Color3.fromRGB(0, 170, 255)
		progressBar.BackgroundColor3 = color
		bgStroke.Color               = color

		local rateLabel = CONFIG.zoneRateLabels[zoneName] or zoneName
		zoneLabel.Text  = "? " .. rateLabel .. " Zone  —  earning XP..."

		slideTo(CONFIG.visiblePosition)
		updateBar()
	end

	local function hideBar()
		inZone         = false
		zoneLabel.Text = ""
		slideTo(CONFIG.hiddenPosition)
	end

	local xpEvents  = ReplicatedStorage.XPEvents
	local zoneEvent = xpEvents.ZoneStatusEvent

	local zoneConn = zoneEvent.OnClientEvent:Connect(function(isInZone: boolean, zoneName: string?)
		if isInZone and zoneName then
			showBar(zoneName)
		else
			hideBar()
		end
	end)

	local attrConn = player:GetAttributeChangedSignal("Points"):Connect(updateBar)

	local currentZone = (player:GetAttribute("CurrentZone") :: string?) or ""
	if currentZone ~= "" then
		showBar(currentZone)
	end

	return {
		destroy = function()
			zoneConn:Disconnect()
			attrConn:Disconnect()
			screenGui:Destroy()
		end,
	}
end

local bar = createXPBar(playerGui)
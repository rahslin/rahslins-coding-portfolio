local RS = game:GetService("ReplicatedStorage")

local GameFolder = RS.Game
local EventFolder = GameFolder.Events
local ModuleFolder = GameFolder.Modules
local ConfigFolder = GameFolder.Settings
local MiscFolder = GameFolder.Misc

local EndJobEvent = EventFolder.EndJob
local ReplicateClient = EventFolder.ReplicateClient

local GameWorkspace = workspace.Game
local Garbage = GameWorkspace.Garbage
local GarbageBags = Garbage.Bags

local EconomyConfig = require(ConfigFolder.Economy)
local GameConfig = require(ConfigFolder.Game)

local Player = game.Players.LocalPlayer
local PlayerData = Player:WaitForChild("PlayerData")
local CashValue = PlayerData:WaitForChild("Cash")
local BankValue = PlayerData:WaitForChild("Bank")

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChild("Humanoid")
local PlayerStats = Character:WaitForChild("Stats")

local Job = "None"
local CurrentNPC, CurrentData

local abbreviations = {
	["k"] = 4,
	["m"] = 7,
	["b"] = 10,
	["t"] = 13,
	["QD"] = 16,
	["QI"] = 19,
	["SE"] = 22,
	["SP"] = 25,
	["O"] = 28,
}

local function Abbr(num)

	local text = tostring(string.format("%.f", math.floor(num)))

	local chosenAbbreviation
	for abbreviation, digit in pairs(abbreviations) do
		if (#text >= digit and #text < (digit + 3)) then
			chosenAbbreviation = abbreviation
			break
		end
	end

	if chosenAbbreviation then
		local digits = abbreviations[chosenAbbreviation]

		local rounded = math.floor(num / 10 ^ (digits - 2)) * 10 ^ (digits - 2)
		text = string.format("%.1f", rounded / 10 ^ (digits - 1)) .. chosenAbbreviation
	else
		text = num
	end

	return text
end

local function Update(IsCash)
	if IsCash then
		local Number = Abbr(CashValue.Value)
		print("Cash:", Number.." "..EconomyConfig.Currency)
	else
		local Number = Abbr(BankValue.Value)
		print("Bank:", Number.." "..EconomyConfig.Currency)
	end
end

PlayerData.Wallet.Changed:Connect(function()
	Update(true)
end)

PlayerData.Bank.Changed:Connect(function()
	Update(false)
end)

Update(true)
Update(false)

EndJobEvent.OnClientEvent:Connect(function()

	if Job == "Mail" then

		Job = "None"

		for _, v in ipairs(game.Workspace.Game.Mail:GetChildren()) do
			local Destination:Part = v
			Destination.Color = Color3.fromRGB(255, 0, 0)

			local Prox = Destination:FindFirstChildOfClass("ProximityPrompt")
			if Prox then
				Prox.Enabled = false
			end

			local Marker = Destination:FindFirstChild("Marker")
			if Marker then
				Marker.Enabled = false
			end
		end

	elseif Job == "Garbage" then

		Job = "None"

	elseif Job == "DeliverFood" then

		Job = "None"

		for _, v in ipairs(game.Workspace.Game.Glovo:GetChildren()) do
			local Destination:Part = v
			Destination.Color = Color3.fromRGB(75, 151, 75)

			local Prox = Destination:FindFirstChildOfClass("ProximityPrompt")
			if Prox then
				Prox.Enabled = false
			end

			local Marker = Destination:FindFirstChild("Marker")
			if Marker then
				Marker.Enabled = false
			end
		end

	end
end)
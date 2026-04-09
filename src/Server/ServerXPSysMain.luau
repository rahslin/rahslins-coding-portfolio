local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PointsStore = DataStoreService:GetDataStore("PlayerPoints")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local XP = require(game.ServerScriptService.Core.XPSys.Settings)

local xpEvents = ReplicatedStorage.XPEvents
local zoneEvent = xpEvents.ZoneStatusEvent

local playerXPData = {}

local function errorFunc(errMsg)
	warn("[XP SYSTEM ERROR]:", errMsg)
end

local function isValidTeam(player)
	local validTeams = XP.ValidTeams
	local playerTeam = player.Team

	if not playerTeam then
		errorFunc(player.Name .. " does not have a team assigned.")
		return false
	end

	for _, team in pairs(validTeams) do
		if playerTeam.Name == team.Name then
			return true
		end
	end
	errorFunc(player.Name .. " is not in a valid team.")
	return false
end

local function getTeamKeyByTeam(teamObj)
	for teamKey, obj in pairs(XP.ValidTeams) do
		if obj == teamObj then
			return teamKey
		end
	end
	return nil
end

local function getRank(points, teamName)
	local rankLadder = XP[teamName]
	if not rankLadder then return "Unknown Rank" end

	local currentRank = rankLadder[1].Name
	for _, rank in ipairs(rankLadder) do
		if points >= rank.XP then
			currentRank = rank.Name
		else
			break
		end
	end
	return currentRank
end

local function loadData(player)
	local playerKey = "Player_" .. player.UserId
	local success, data = pcall(function()
		return PointsStore:GetAsync(playerKey)
	end)

	if not success then
		errorFunc("Failed to load data for " .. player.Name .. ": " .. data)
	end

	playerXPData[player] = data or {}

	local team = player.Team
	if team then
		local teamData = playerXPData[player][team.Name] or { Points = 0 }
		player:SetAttribute("Points", teamData.Points)
		player:SetAttribute("Rank", getRank(teamData.Points, getTeamKeyByTeam(team)))
	end
end

local function saveData(player)
	local playerKey = "Player_" .. player.UserId
	local data = playerXPData[player]
	if not data then return end

	local success, err = pcall(function()
		PointsStore:SetAsync(playerKey, data)
	end)

	if not success then
		errorFunc("Failed to save data for " .. player.Name .. ": " .. err)
	else
		print("[SAVE]: Saved data for", player.Name)
	end
end

local function givePoints(player, amount)
	local team = player.Team
	if not team then return end

	local teamKey = getTeamKeyByTeam(team)
	if not teamKey then return end

	local xpData = playerXPData[player] or {}
	local teamData = xpData[team.Name] or { Points = 0 }
	teamData.Points += amount

	xpData[team.Name] = teamData
	playerXPData[player] = xpData

	player:SetAttribute("Points", teamData.Points)
	player:SetAttribute("Rank", getRank(teamData.Points, teamKey))

	print("[GIVE]:", player.Name, "got", amount, "in", team.Name, "Total:", teamData.Points)
end

local function applyPointsAtIntervals()
	while true do
		task.wait(XP.time)
		for _, player in ipairs(Players:GetPlayers()) do
			if isValidTeam(player) then
				givePoints(player, XP.points)
			else
				errorFunc(player.Name .. " is not in a valid team to receive points.")
			end
		end
	end
end

local XPZones = workspace.XP

local zoneRates = {
	["1XP"]  = 1,
	["5XP"]  = 5,
	["10XP"] = 10,
}

local playersInZone = {}

task.spawn(function()
	while true do
		for player, rate in pairs(playersInZone) do
			if player and player:IsDescendantOf(game) then
				givePoints(player, rate)
			else
				playersInZone[player] = nil
			end
		end
		task.wait(1200)
	end
end)

local function onZoneTouched(zonePart)
	zonePart.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player or playersInZone[player] then return end

		playersInZone[player] = zoneRates[zonePart.Name]
		player:SetAttribute("CurrentZone", zonePart.Name)
		zoneEvent:FireClient(player, true, zonePart.Name)
	end)

	zonePart.TouchEnded:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player or not playersInZone[player] then return end

		playersInZone[player] = nil
		player:SetAttribute("CurrentZone", "")
		zoneEvent:FireClient(player, false, nil)
	end)
end

for _, zonePart in ipairs(XPZones:GetChildren()) do
	if zonePart:IsA("BasePart") then
		if not zoneRates[zonePart.Name] then
			warn("[SETUP]: Zone", zonePart.Name, "has no rate defined — defaulting to 1.")
			zoneRates[zonePart.Name] = 1
		end
		onZoneTouched(zonePart)
	end
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("CurrentZone", "")
	loadData(player)

	player:GetPropertyChangedSignal("Team"):Connect(function()
		local xpData = playerXPData[player] or {}
		local team = player.Team
		if team then
			local teamKey = getTeamKeyByTeam(team)
			local teamData = xpData[team.Name] or { Points = 0 }
			player:SetAttribute("Points", teamData.Points)
			player:SetAttribute("Rank", getRank(teamData.Points, teamKey))
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	playersInZone[player] = nil
end)

task.spawn(applyPointsAtIntervals)
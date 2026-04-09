local LOCKER_NAME = "Locker"
local PROXIMITY_PROMPT_NAME = "LockerPrompt"

local ALLOWED_TEAMS = {
	"Police",
	"SWAT",
	"Sheriff",
}

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "LockerRemotes"
remoteFolder.Parent = ReplicatedStorage

local function createRemote(name, class)
	local remote = Instance.new(class)
	remote.Name = name
	remote.Parent = remoteFolder
	return remote
end

local equipHatRemote   = createRemote("EquipHat",   "RemoteEvent")
local equipShirtRemote = createRemote("EquipShirt", "RemoteEvent")
local equipPantsRemote = createRemote("EquipPants", "RemoteEvent")
local equipVestRemote  = createRemote("EquipVest",  "RemoteEvent")
local openLockerRemote = createRemote("OpenLocker", "RemoteEvent")
local getItemsRemote   = createRemote("GetItems",   "RemoteFunction")

local itemsFolder = ServerStorage:WaitForChild("LockerItems")
local hatsFolder  = itemsFolder:WaitForChild("Hats")
local shirtsFolder = itemsFolder:WaitForChild("Shirts")
local pantsFolder = itemsFolder:WaitForChild("Pants")
local vestsFolder = itemsFolder:WaitForChild("Vests")

local equippedByPlayer = {}

local function isTeamAllowed(player)
	if #ALLOWED_TEAMS == 0 then return true end
	if not player.Team then return false end
	for _, teamName in ipairs(ALLOWED_TEAMS) do
		if player.Team.Name == teamName then return true end
	end
	return false
end

local function getEquipped(player)
	if not equippedByPlayer[player.UserId] then
		equippedByPlayer[player.UserId] = {}
	end
	return equippedByPlayer[player.UserId]
end

local function weldParts(root, model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= root then
			local weld = Instance.new("Weld")
			weld.Part0 = root
			weld.Part1 = part
			weld.C0 = root.CFrame:Inverse() * part.CFrame
			weld.Parent = root
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
		end
	end
end

local function equipHat(player, name)
	if not isTeamAllowed(player) then return end
	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end

	local equipped = getEquipped(player)

	if equipped.Hat and equipped.Hat.Name == name then
		equipped.Hat:Destroy()
		equipped.Hat = nil
		return
	end

	if equipped.Hat then
		equipped.Hat:Destroy()
	end

	local template = hatsFolder:FindFirstChild(name)
	if not template then return end

	local hat = template:Clone()
	local middle = hat:FindFirstChild("Middle")
	if not middle then
		warn("Hat model is missing a Middle part:", name)
		return
	end

	local originalRotation = middle.CFrame - middle.CFrame.Position

	hat.Parent = char
	hat.PrimaryPart = middle

	for _, part in ipairs(hat:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
		end
	end

	for _, part in ipairs(hat:GetDescendants()) do
		if part:IsA("BasePart") and part ~= middle then
			local weld = Instance.new("Weld")
			weld.Part0 = middle
			weld.Part1 = part
			weld.C0 = middle.CFrame:Inverse() * part.CFrame
			weld.Parent = middle
		end
	end

	local headWeld = Instance.new("Weld")
	headWeld.Part0 = head
	headWeld.Part1 = middle
	headWeld.C0 = CFrame.new(0, head.Size.Y / 2, 0)
	headWeld.C1 = originalRotation
	headWeld.Parent = head

	middle.Transparency = 1
	equipped.Hat = hat
end

local function equipShirt(player, name)
	if not isTeamAllowed(player) then return end
	local char = player.Character
	if not char then return end

	local equipped = getEquipped(player)

	local existing = char:FindFirstChildOfClass("Shirt")
	if existing then existing:Destroy() end

	if equipped.Shirt == name then
		equipped.Shirt = nil
		return
	end

	local template = shirtsFolder:FindFirstChild(name)
	if not template then return end

	template:Clone().Parent = char
	equipped.Shirt = name
end

local function equipPants(player, name)
	if not isTeamAllowed(player) then return end
	local char = player.Character
	if not char then return end

	local equipped = getEquipped(player)

	local existing = char:FindFirstChildOfClass("Pants")
	if existing then existing:Destroy() end

	if equipped.Pants == name then
		equipped.Pants = nil
		return
	end

	local template = pantsFolder:FindFirstChild(name)
	if not template then return end

	template:Clone().Parent = char
	equipped.Pants = name
end

local function equipVest(player, name)
	if not isTeamAllowed(player) then return end
	local char = player.Character
	if not char then return end
	local torso = char:FindFirstChild("Torso")
	if not torso then return end

	local equipped = getEquipped(player)

	if equipped.Vest and equipped.Vest.Name == name then
		equipped.Vest:Destroy()
		equipped.Vest = nil
		return
	end

	if equipped.Vest then
		equipped.Vest:Destroy()
	end

	local template = vestsFolder:FindFirstChild(name)
	if not template then return end

	local vest = template:Clone()
	local middle = vest:FindFirstChild("Middle")
	if not middle then return end

	vest.Parent = char
	vest.PrimaryPart = middle
	vest:SetPrimaryPartCFrame(torso.CFrame)

	weldParts(middle, vest)

	local torsoWeld = Instance.new("Weld")
	torsoWeld.Part0 = torso
	torsoWeld.Part1 = middle
	torsoWeld.C0 = torso.CFrame:Inverse() * middle.CFrame
	torsoWeld.Parent = torso

	middle.Transparency = 1
	equipped.Vest = vest
end

local locker = workspace:FindFirstChild(LOCKER_NAME)
if locker then
	local prompt = locker:FindFirstChild(PROXIMITY_PROMPT_NAME)
	if prompt then
		prompt.Triggered:Connect(function(player)
			if not isTeamAllowed(player) then return end

			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://9119634456"
			sound.Volume = 0.25
			sound.Parent = player:WaitForChild("PlayerGui")
			sound:Play()
			game:GetService("Debris"):AddItem(sound, 5)

			openLockerRemote:FireClient(player)
		end)
	end
end

getItemsRemote.OnServerInvoke = function(player)
	if not isTeamAllowed(player) then return {} end

	local data = { Hats = {}, Shirts = {}, Pants = {}, Vests = {} }

	for _, v in ipairs(hatsFolder:GetChildren()) do
		if v:IsA("Model") then table.insert(data.Hats, v.Name) end
	end
	for _, v in ipairs(shirtsFolder:GetChildren()) do
		if v:IsA("Shirt") then table.insert(data.Shirts, v.Name) end
	end
	for _, v in ipairs(pantsFolder:GetChildren()) do
		if v:IsA("Pants") then table.insert(data.Pants, v.Name) end
	end
	for _, v in ipairs(vestsFolder:GetChildren()) do
		if v:IsA("Model") then table.insert(data.Vests, v.Name) end
	end

	return data
end

equipHatRemote.OnServerEvent:Connect(equipHat)
equipShirtRemote.OnServerEvent:Connect(equipShirt)
equipPantsRemote.OnServerEvent:Connect(equipPants)
equipVestRemote.OnServerEvent:Connect(equipVest)

Players.PlayerRemoving:Connect(function(player)
	equippedByPlayer[player.UserId] = nil
end)

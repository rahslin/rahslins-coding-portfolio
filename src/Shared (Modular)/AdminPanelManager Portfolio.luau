--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Debris = game:GetService("Debris")

local Source = ReplicatedStorage.Source
local Remotes = script.Parent.Parent.Remotes

local AdminPanelRegistry = require(script.Parent.AdminPanelRegistry)
local AdminPanelProcessor = require(script.Parent.AdminPanelProcessor)
local AnnouncementManager = require(Source.Announcement.Core.AnnouncementManager)
local EconomyRegistry = require(Source.Economy.Core.EconomyRegistry)
local BrainrotRegistry = require(Source.Brainrot.Core.BrainrotRegistry)
local EventProcessor = require(Source.Event.Core.EventProcessor)
local GunRegistry = require(Source.Gun.Core.GunRegistry)
local GunProcessor = require(Source.Gun.Core.GunProcessor)
local StealRegistry = require(Source.Steal.Core.StealRegistry)

local AdminPanelManager = {}

function AdminPanelManager.init()
	AdminPanelManager.defineCommands()
	AdminPanelManager.defineAdminGroups()
	AdminPanelManager.defineRoles()
	AdminPanelManager.setupEventHandlers()
	AdminPanelManager.setupEventDrivers()
end

function AdminPanelManager.defineCommands()
	AdminPanelRegistry.registerCommand({
		name = 'eventVoice',
		aliases = {'voice', 'playsound'},
		description = 'Plays the event voice for all players',
		arguments = {},
		permission = 'Developers',
		cooldown = 5,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			Remotes.EventVoice:FireAllClients('127806674529968')
			return {ok = true, err = 'Playing EventVoice for all players'}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'skyEffect',
		aliases = {'sky', 'skypreset'},
		description = 'Changes the sky to a preset for 3 minutes',
		arguments = {
			{name = 'preset', typeOf = 'string', required = true}
		},
		permission = 'Developers',
		cooldown = 10,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local ServerStorage = game:GetService("ServerStorage")
			local Lighting = game:GetService("Lighting")

			local preset = string.lower(arguments.preset :: string)

			local skyNameMap: {[string]: string} = {
				pink  = 'PinkSky',
				green = 'GreenSky',
				red = "RedSky",
			}

			local skyName = skyNameMap[preset]
			if not skyName then
				return {ok = false, err = `Sky preset '{preset}' not found. Valid: pink, green, red`}
			end

			local eventSkyboxes = ServerStorage:FindFirstChild("EventSkyboxes")
			if not eventSkyboxes then
				return {ok = false, err = 'EventSkyboxes folder not found in ServerStorage'}
			end

			local newSky = eventSkyboxes:FindFirstChild(skyName) :: Sky
			if not newSky then
				return {ok = false, err = `Sky '{skyName}' not found in EventSkyboxes`}
			end

			local existingSky = Lighting:FindFirstChildOfClass("Sky")
			local originalSkyClone: Sky? = nil
			if existingSky then
				originalSkyClone = existingSky:Clone() :: Sky
				existingSky:Destroy()
			end

			local appliedSky = newSky:Clone()
			appliedSky.Parent = Lighting

			task.delay(180, function()
				local current = Lighting:FindFirstChildOfClass("Sky")
				if current then
					current:Destroy()
				end
				if originalSkyClone then
					originalSkyClone.Parent = Lighting
				end
			end)

			return {ok = true, err = `Sky set to {preset} for 3 minutes`}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'tp',
		aliases = {'teleport'},
		description = 'Teleport to a player',
		arguments = {
			{name = 'target', typeOf = 'Player', required = true}
		},
		cooldown = 1,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local target = arguments.target::Player
			local executor = Players:GetPlayerByUserId(playerId)
			if not executor then
				return {ok = false, err = 'Executor not in server'}
			end
			if not executor.Character then
				return {ok = false, err = 'Executor character not found'}
			end
			if not target.Character then
				return {ok = false, err = 'Target character not found'}
			end
			local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")::BasePart
			local executorRoot = executor.Character:FindFirstChild("HumanoidRootPart")::BasePart
			if not targetRoot then
				return {ok = false, err = 'Target rootPart not found'}
			end
			if not executorRoot then
				return {ok = false, err = 'Executor rootPart not found'}
			end
			executorRoot.CFrame = targetRoot.CFrame + Vector3.new(3, 0, 0)
			return {ok = true, err = `Teleported to {executor.DisplayName}`}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'addmoney',
		aliases = {'mulla', 'givemoney', 'handout'},
		description = 'Give money to a player',
		arguments = {
			{name = 'player', typeOf = 'Player', required = true},
			{name = 'amount', typeOf = 'number', required = true}
		},
		permission = 'Developers',
		cooldown = 5,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local player = arguments.player::Player
			local amount = arguments.amount::number
			EconomyRegistry.updatePlayerBalance(player.UserId, amount)
			return {ok = true, err = `Awarded {amount} money to {player.DisplayName}`}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'spawnBrainrotOnRoad',
		aliases = {'spawn'},
		description = 'Spawn a brainrot on the road',
		arguments = {
			{name = 'class', typeOf = 'string', required = true},
			{name = 'rarity', typeOf = 'string', required = false},
			{name = 'variant', typeOf = 'string', required = false},
		},
		permission = 'Developers',
		cooldown = 6,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local classId = assert(arguments.class::string)
			local rarityId = arguments.rarity::string?

			if not BrainrotRegistry.getBrainrotClass(classId) then
				return {ok = false, err = 'Brainrot class not found'}
			end
			if rarityId and not BrainrotRegistry.getRarityTier(rarityId) then
				return {ok = false, err = 'Rarity tier not found'}
			end

			BrainrotRegistry.addSpawnOverride(classId, rarityId)
			return {ok = true}
		end
	})

	AdminPanelRegistry.registerCommand({
		name = 'spawnBrainrotForServer',
		aliases = {'spawnServer'},
		description = 'Spawn a brainrot for all players in this server',
		arguments = {
			{name = 'class', typeOf = 'string', required = true},
			{name = 'rarity', typeOf = 'string', required = false},
			{name = 'variant', typeOf = 'string', required = false},
		},
		permission = 'Developers',
		cooldown = 6,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local classId = assert(arguments.class::string)
			local rarityId = arguments.rarity::string?
			local variantId = arguments.variant::string?

			if not BrainrotRegistry.getBrainrotClass(classId) then
				return {ok = false, err = 'Brainrot class not found'}
			end
			if rarityId and not BrainrotRegistry.getRarityTier(rarityId) then
				return {ok = false, err = 'Rarity tier not found'}
			end
			if variantId and not BrainrotRegistry.getRarityTier(variantId) then
				return {ok = false, err = 'Variant tier not found'}
			end

			BrainrotRegistry.addSpawnOverride(classId, rarityId, variantId)

			return {ok = true, err = `Spawned {classId} for all players in this server`}
		end
	})

	AdminPanelRegistry.registerCommand({
		name = 'spawnBrainrotForAllServers',
		aliases = {'spawnAll'},
		description = 'Spawn a brainrot across ALL servers via MessagingService + MemoryStore',
		arguments = {
			{name = 'class', typeOf = 'string', required = true},
			{name = 'rarity', typeOf = 'string', required = false},
			{name = 'variant', typeOf = 'string', required = false},
		},
		permission = 'Developers',
		cooldown = 15,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local classId = assert(arguments.class::string)
			local rarityId = arguments.rarity::string?
			local variantId = arguments.variant::string?

			if not BrainrotRegistry.getBrainrotClass(classId) then
				return {ok = false, err = 'Brainrot class not found'}
			end
			if rarityId and not BrainrotRegistry.getRarityTier(rarityId) then
				return {ok = false, err = 'Rarity tier not found'}
			end
			if variantId and not BrainrotRegistry.getRarityTier(variantId) then
				return {ok = false, err = 'Variant tier not found'}
			end

			local overrideKey = `global_{classId}_{os.time()}`

			local writeOk = pcall(function()
				local map = MemoryStoreService:GetSortedMap("BrainrotSpawnOverrides")
				map:SetAsync(overrideKey, {
					class   = classId,
					rarity  = rarityId,
					variant = variantId,
					by      = playerId,
					at      = os.time(),
				}, 300)
			end)

			if not writeOk then
				return {ok = false, err = 'MemoryStore write failed'}
			end

			local pubOk = pcall(function()
				MessagingService:PublishAsync("BrainrotSpawnOverride", {
					class   = classId,
					rarity  = rarityId,
					variant = variantId,
					key     = overrideKey,
					by      = playerId,
				})
			end)

			if not pubOk then
				return {ok = false, err = 'MessagingService publish failed'}
			end

			return {ok = true, err = `Broadcast spawn of {classId} to all servers`}
		end
	})

	AdminPanelRegistry.registerCommand({
		name = 'antiSteal',
		aliases = {'antisteal', 'protect'},
		description = 'Prevents a player from being stolen from for 5 minutes',
		arguments = {
			{name = 'player', typeOf = 'Player', required = true}
		},
		permission = 'Developers',
		cooldown = 3,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local target = arguments.player :: Player
			StealRegistry.setAntiSteal(target.UserId, 300)
			AnnouncementManager.notify(target.UserId, {
				message = 'You are protected from stealing for 5 minutes!',
				duration = 5,
			})
			return {ok = true, err = `Anti-steal applied to {target.DisplayName} for 5 minutes`}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'startEvent',
		aliases = {'eventStart'},
		description = 'Starts an event in the current server',
		arguments = {
			{name = 'eventName', typeOf = 'string', required = true},
		},
		permission = 'Developers',
		cooldown = 3,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local eventName = assert(arguments.eventName::string)
			local result = EventProcessor.startEvent(eventName)
			if not result.ok then
				return result
			end
			return {ok = true}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'stopEvent',
		aliases = {'eventStop'},
		description = 'Stops an event in the current server',
		arguments = {
			{name = 'reason', typeOf = 'string', required = false}
		},
		permission = 'Developers',
		cooldown = 5,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local result = EventProcessor.stopActiveEvent(arguments.reason)
			if not result.ok then
				return result
			end
			return {ok = true}
		end
	})

	AdminPanelRegistry.registerCommand({
		name = 'spawnGun',
		aliases = {'gunSpawn'},
		description = 'Spawn a gun for the player',
		arguments = {
			{name = 'player', typeOf = 'Player', required = true},
			{name = 'gunName', typeOf = 'string', required = true}
		},
		permission = 'Developers',
		cooldown = 3,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local player = assert(arguments.player::Player)
			local gunName = assert(arguments.gunName::string)
			local result = GunProcessor.grantGun(player.UserId, gunName)
			if not result.ok then
				return result
			end
			return {ok = true, err = `Successfully gave {player.DisplayName} a {gunName}`}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'serverAnnounce',
		aliases = {'announceServer', 'announce'},
		description = 'Sends a message to all players in the server',
		arguments = {
			{name = 'message', typeOf = 'string', required = true},
		},
		permission = 'Developers',
		cooldown = 5,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local message = assert(arguments.message::string)
			AnnouncementManager.announce({
				message = message,
				duration = 5,
			})
			return {ok = true, err = 'Successfully sent message!'}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'rotateGuns',
		aliases = {'gunsRotate', 'newGuns'},
		description = 'Overrides the next gun rotation for the regular gun shop',
		arguments = {},
		permission = 'Developers',
		cooldown = 3,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			return GunRegistry.queueGunRotationOverride()
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'flingUser',
		aliases = {'fling'},
		description = 'Flings a player into the air',
		arguments = {
			{name = 'player', typeOf = 'Player', required = true}
		},
		permission = 'Developers',
		cooldown = 3,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local target = arguments.player::Player
			if not target.Character then
				return {ok = false, err = 'Target character not found'}
			end
			local rootPart = target.Character:FindFirstChild("HumanoidRootPart")::BasePart
			if not rootPart then
				return {ok = false, err = 'Target rootPart not found'}
			end
			local attachment = Instance.new("Attachment")
			attachment.Parent = rootPart
			local force = Instance.new("LinearVelocity")
			force.Attachment0 = attachment
			force.MaxForce = math.huge
			force.VectorVelocity = Vector3.new(
				math.random(-80, 80),
				180,
				math.random(-80, 80)
			)
			force.Parent = rootPart
			Debris:AddItem(force, 0.12)
			Debris:AddItem(attachment, 0.12)
			return {ok = true, err = `Flung {target.DisplayName}`}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'jumpscareUser',
		aliases = {'jumpscare'},
		description = 'Sends a jumpscare to a player',
		arguments = {
			{name = 'player', typeOf = 'Player', required = true}
		},
		permission = 'Developers',
		cooldown = 5,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local target = arguments.player::Player
			Remotes.TrollJumpscare:FireClient(target)
			return {ok = true, err = `Jumpscared {target.DisplayName}`}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'enlargeUser',
		aliases = {'enlarge', 'bigify'},
		description = 'Makes a player very large',
		arguments = {
			{name = 'player', typeOf = 'Player', required = true}
		},
		permission = 'Developers',
		cooldown = 3,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local target = arguments.player::Player
			if not target.Character then
				return {ok = false, err = 'Target character not found'}
			end
			local humanoid = target.Character:FindFirstChildOfClass("Humanoid")::Humanoid
			if not humanoid then
				return {ok = false, err = 'Target humanoid not found'}
			end
			local scales = {"BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale"}
			for _, scaleName in scales do
				local scaleValue = humanoid:FindFirstChild(scaleName) :: NumberValue
				if scaleValue then
					scaleValue.Value = 5
				end
			end
			return {ok = true, err = `Enlarged {target.DisplayName}`}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'makeUserSmall',
		aliases = {'trollify', 'shrink', 'smallify'},
		description = 'Makes a player tiny',
		arguments = {
			{name = 'player', typeOf = 'Player', required = true}
		},
		permission = 'Developers',
		cooldown = 3,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local target = arguments.player::Player
			if not target.Character then
				return {ok = false, err = 'Target character not found'}
			end
			local humanoid = target.Character:FindFirstChildOfClass("Humanoid")::Humanoid
			if not humanoid then
				return {ok = false, err = 'Target humanoid not found'}
			end
			local scales = {"BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale"}
			for _, scaleName in scales do
				local scaleValue = humanoid:FindFirstChild(scaleName) :: NumberValue
				if scaleValue then
					scaleValue.Value = 0.25
				end
			end
			return {ok = true, err = `Shrunk {target.DisplayName}`}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'makeUserSpeedy',
		aliases = {'speedy', 'speeduser'},
		description = 'Makes a player extremely fast',
		arguments = {
			{name = 'player', typeOf = 'Player', required = true}
		},
		permission = 'Developers',
		cooldown = 3,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local target = arguments.player::Player
			if not target.Character then
				return {ok = false, err = 'Target character not found'}
			end
			local humanoid = target.Character:FindFirstChildOfClass("Humanoid")::Humanoid
			if not humanoid then
				return {ok = false, err = 'Target humanoid not found'}
			end
			humanoid.WalkSpeed = 200
			task.delay(10, function()
				if target.Character then
					local h = target.Character:FindFirstChildOfClass("Humanoid")::Humanoid
					if h then
						h.WalkSpeed = 16
					end
				end
			end)
			return {ok = true, err = `Made {target.DisplayName} speedy for 10s`}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'invisibleUser',
		aliases = {'invisible', 'invis'},
		description = 'Makes a player invisible for 10 seconds',
		arguments = {
			{name = 'player', typeOf = 'Player', required = true}
		},
		permission = 'Developers',
		cooldown = 3,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local target = arguments.player :: Player
			if not target.Character then
				return {ok = false, err = 'Target character not found'}
			end
			for _, part in target.Character:GetDescendants() do
				if part:IsA("BasePart") or part:IsA("Decal") then
					(part :: any).Transparency = 1
				end
			end
			task.delay(10, function()
				if not target.Character then return end
				for _, part in target.Character:GetDescendants() do
					if part:IsA("BasePart") then
						(part :: any).Transparency = if part.Name == "HumanoidRootPart" then 1 else 0
					elseif part:IsA("Decal") then
						(part :: any).Transparency = 0
					end
				end
			end)
			return {ok = true, err = `Made {target.DisplayName} invisible for 10s`}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'blindUser',
		aliases = {'blind'},
		description = 'Blinds a player for 10 seconds',
		arguments = {
			{name = 'player', typeOf = 'Player', required = true}
		},
		permission = 'Developers',
		cooldown = 5,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local target = arguments.player :: Player
			Remotes.TrollBlind:FireClient(target, 10)
			return {ok = true, err = `Blinded {target.DisplayName} for 10s`}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'flyUser',
		aliases = {'fly'},
		description = 'Lets a player fly for 15 seconds',
		arguments = {
			{name = 'player', typeOf = 'Player', required = true}
		},
		permission = 'Developers',
		cooldown = 5,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local target = arguments.player :: Player
			if not target.Character then
				return {ok = false, err = 'Target character not found'}
			end
			Remotes.TrollFly:FireClient(target, 15)
			return {ok = true, err = `{target.DisplayName} is now flying for 15s`}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'explodeUser',
		aliases = {'explode'},
		description = 'Explodes a player',
		arguments = {
			{name = 'player', typeOf = 'Player', required = true}
		},
		permission = 'Developers',
		cooldown = 5,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local target = arguments.player :: Player
			if not target.Character then
				return {ok = false, err = 'Target character not found'}
			end
			local rootPart = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart
			if not rootPart then
				return {ok = false, err = 'Target rootPart not found'}
			end
			local explosion = Instance.new("Explosion")
			explosion.Position = rootPart.Position
			explosion.BlastRadius = 10
			explosion.BlastPressure = 500000
			explosion.DestroyJointRadiusPercent = 0
			explosion.Parent = workspace
			Debris:AddItem(explosion, 2)
			return {ok = true, err = `Exploded {target.DisplayName}`}
		end,
	})

	AdminPanelRegistry.registerCommand({
		name = 'refreshUser',
		aliases = {'refresh', 'reset', 'respawn'},
		description = 'Resets a player character',
		arguments = {
			{name = 'player', typeOf = 'Player', required = true}
		},
		permission = 'Developers',
		cooldown = 3,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			local target = arguments.player :: Player
			target:LoadCharacterAsync()
			return {ok = true, err = `Refreshed {target.DisplayName}`}
		end,
	})

	-- LUCKY BLOCK COMMAND
	AdminPanelRegistry.registerCommand({
		name = 'spawnLuckyBlock',
		aliases = {'luckyblock', 'lucky'},
		description = 'Spawn a lucky block on the road',
		arguments = {
			{name = 'type', typeOf = 'string', required = true}, -- common, rare, mythic, undead
		},
		permission = 'Developers',
		cooldown = 3,
		execute = function(playerId: number, arguments: {[any]: any})
			: {ok: boolean, err: string?}
			-- lucky blocks are under maintenance, this will no longer spawn to avoid breaking functionality.
			return {ok = false, err = 'Command is under maintenance by Duke!'}
		end,
	})
end

function AdminPanelManager.defineRoles()
	AdminPanelProcessor.resolveRoleHierarchy()
end

function AdminPanelManager.defineAdminGroups()
	AdminPanelRegistry.registerAdminGroup(676641571)
end

function AdminPanelManager.onPlayerAdded(player: Player)
	local playerId = player.UserId
	local playerAdminData = AdminPanelRegistry.onPlayerAdded(playerId)
	AdminPanelProcessor.resolvePlayerAdminData(
		playerId,
		playerAdminData,
		AdminPanelRegistry.savedPlayerAdminData[playerId]
	)
end

function AdminPanelManager.onPlayerRemoving(player: Player)
	local playerId = player.UserId
	AdminPanelRegistry.onPlayerRemoving(playerId)
end

function AdminPanelManager.setupEventHandlers()
	MessagingService:SubscribeAsync("BrainrotSpawnOverride", function(message: {Data: any})
		local data = message.Data
		if not data or not data.class then return end

		local classId   = data.class :: string
		local rarityId  = data.rarity :: string?
		local variantId = data.variant :: string?

		if not BrainrotRegistry.getBrainrotClass(classId) then return end
		if rarityId and not BrainrotRegistry.getRarityTier(rarityId) then return end
		if variantId and not BrainrotRegistry.getRarityTier(variantId) then return end

		BrainrotRegistry.addSpawnOverride(classId, rarityId, variantId)
	end)
end

function AdminPanelManager.setupEventDrivers()
	for _, player in Players:GetPlayers() do
		task.spawn(AdminPanelManager.onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(AdminPanelManager.onPlayerAdded)
	Players.PlayerRemoving:Connect(AdminPanelManager.onPlayerRemoving)
	Remotes.RequestExecuteCommand.OnServerInvoke = function(player: Player, commandText: string)
		assert(typeof(commandText) == 'string')
		local result = AdminPanelProcessor.executeCommand(player.UserId, commandText)
		return result
	end
	Remotes.RequestExecuteCommandWithArgs.OnServerInvoke = function(player: Player, commandName: string, arguments: {[string]: any})
		assert(typeof(commandName) == 'string')
		assert(typeof(arguments) == 'table')
		local result = AdminPanelProcessor.executeCommandWithArgs(player.UserId, commandName, arguments)
		return result
	end
end

return AdminPanelManager
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local General = require(ReplicatedStorage:WaitForChild("General"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RunService = game:GetService("RunService")

local UpdateCombatStates = Remotes:WaitForChild("UpdateCombatStates")
local S_UpdateCombatStates = Remotes:WaitForChild("S_UpdateCombatStates")
local GetCombatStates = Remotes:WaitForChild("GetCombatStates")
local S_GetCombatStates = Remotes:WaitForChild("S_GetCombatStates")

local HitCharacter = Remotes:WaitForChild("HitCharacter")

local module = {}

function module.GetStateIndex(storage, plr)
	for i,combatState in pairs(storage) do
		if combatState.Player == plr then
			return i
		end
	end
	return nil
end

function module.CheckIfInBlockZone(attacker,target,min,max)
	local attackerHRP = attacker:WaitForChild("HumanoidRootPart")
	local targetHRP = target:WaitForChild("HumanoidRootPart")
	if attackerHRP and targetHRP then
		local targetLV = targetHRP.CFrame.lookVector*1
		local normalUnitVector = ((attackerHRP.Position - targetHRP.Position)/(attackerHRP.Position - targetHRP.Position).magnitude)*100
		
		local result = targetLV:Dot(normalUnitVector)
		print(result)
		
		if result >= min and result <= max then
			return true
		else
			return false
		end
	end
end

function module.HitCharacter(attacker, chr, combatStates, tool)
	local config = tool:WaitForChild("Configuration")
	local attackDamage = config:WaitForChild("AttackDamage").Value
	local chrPlayer = Players:GetPlayerFromCharacter(chr)
	if chrPlayer then
		local plrState = combatStates[module.GetStateIndex(combatStates,chrPlayer)]
		if plrState then
			local hum = chr:WaitForChild("Humanoid")
			local inBlockZone = module.CheckIfInBlockZone(attacker, chr, -45, 100)
			if plrState.Blocking == true and inBlockZone then
				return "Blocked"
			else
				hum.Health = hum.Health - attackDamage
				return "Hit"
			end
		end
	end
end

function module.UseEnergy(plr, amount, combatState)
	if game:GetService("RunService"):IsClient() then
		if combatState.Energy >= amount then
			combatState.Energy = combatState.Energy - amount
			UpdateCombatStates:FireServer(combatState)
			return true
		else
			return false
		end
	else
		return true
	end
end

return module

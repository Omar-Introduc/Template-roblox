-- src/server/ShopService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(Shared:WaitForChild("ShopConfig"))

local Events = ReplicatedStorage:WaitForChild("Events")
local BuyItemFunction = Events:WaitForChild("BuyItem")

local ShopService = {}

function ShopService.ApplyEffect(character, item)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local itemType = item.Type
	local value = item.Value or 0
	local now = os.time()

	if itemType == "Speed" then
		humanoid.WalkSpeed = value
		character:SetAttribute("Buff_WalkSpeed", value) -- Used for verification
	elseif itemType == "Jump" then
		humanoid.JumpPower = value
		humanoid.UseJumpPower = true
		character:SetAttribute("Buff_JumpPower", value)
	elseif itemType == "Gravity" then
		-- Efecto de gravedad baja usando VectorForce (Moderno)
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- Limpiar attachment/fuerza anterior si existe
			local oldAtt = hrp:FindFirstChild("GravityAttachment")
			if oldAtt then oldAtt:Destroy() end

			local att = Instance.new("Attachment")
			att.Name = "GravityAttachment"
			att.Parent = hrp

			local force = Instance.new("VectorForce")
			force.Name = "LowGravForce"
			force.Attachment0 = att
			force.Force = Vector3.new(0, hrp:GetMass() * workspace.Gravity * (1 - value), 0)
			force.RelativeTo = Enum.ActuatorRelativeTo.World
			force.Parent = hrp

			-- Duración 30s
			local duration = 30
			character:SetAttribute("Buff_Gravity_End", now + duration)

			task.delay(duration, function()
				if character and character:IsDescendantOf(workspace) then
					character:SetAttribute("Buff_Gravity_End", nil)
					if hrp then
						local f = hrp:FindFirstChild("LowGravForce")
						if f then f:Destroy() end
						local a = hrp:FindFirstChild("GravityAttachment")
						if a then a:Destroy() end
					end
				end
			end)
		end
	elseif itemType == "Protect" then
		character:SetAttribute("HasShield", true)
		local highlight = Instance.new("Highlight")
		highlight.Name = "ShieldHighlight"
		highlight.FillColor = Color3.fromRGB(255, 0, 100)
		highlight.Parent = character
	elseif itemType == "Heal" then
		humanoid.Health = humanoid.MaxHealth
	elseif itemType == "God" then
		-- God Mode (Inmortalidad)
		local duration = value > 0 and value or 5
		character:SetAttribute("Buff_God_End", now + duration)

		local ff = Instance.new("ForceField")
		ff.Name = "GodModeFF"
		ff.Visible = true
		ff.Parent = character

		task.delay(duration, function()
			if character and character:IsDescendantOf(workspace) then
				character:SetAttribute("Buff_God_End", nil)
				local currentFF = character:FindFirstChild("GodModeFF")
				if currentFF then currentFF:Destroy() end
			end
		end)
	elseif itemType == "Fly" then
		-- Fly
		local duration = value > 0 and value or 10
		character:SetAttribute("Buff_Fly_End", now + duration)

		task.delay(duration, function()
			if character and character:IsDescendantOf(workspace) then
				character:SetAttribute("Buff_Fly_End", nil)
			end
		end)
	elseif itemType == "DoubleJump" then
		-- Double Jump (Permanente)
		character:SetAttribute("Buff_DoubleJump", true)
	elseif itemType == "Multiplier" then
		-- Multiplier
		local duration = 60 -- 1 minuto
		character:SetAttribute("PointMultiplier", value)
		character:SetAttribute("Buff_Multiplier_End", now + duration)

		task.delay(duration, function()
			if character and character:IsDescendantOf(workspace) then
				character:SetAttribute("PointMultiplier", 1)
				character:SetAttribute("Buff_Multiplier_End", nil)
			end
		end)
	end
end

function ShopService.ProcessPurchase(player, itemId)
	-- Buscar item en todas las categorías
	local itemData = nil
	for _, cat in pairs(ShopConfig.Categories) do
		for _, item in ipairs(cat.Items) do
			if item.Id == itemId then
				itemData = item
				break
			end
		end
		if itemData then break end
	end

	if not itemData then return false, "Error" end

	-- Verificar si ya lo tiene (si es permanente)
	if itemData.Id == "DoubleJump" then
		if player:GetAttribute("Owns_DoubleJump") == true then
			return false, "Ya lo tienes"
		end
	end

	-- Support both 'Points' (from old scripts) and 'CR' (from newer scripts) for money
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return false, "No leaderstats" end

	local moneyStat = leaderstats:FindFirstChild("Points") or leaderstats:FindFirstChild("CR")

	if not moneyStat or moneyStat.Value < itemData.Price then
		return false, "Pobretón"
	end

	moneyStat.Value = moneyStat.Value - itemData.Price

	-- Marcar propiedad permanente en el Player para que DataService lo guarde
	if itemData.Id == "DoubleJump" then
		player:SetAttribute("Owns_DoubleJump", true)
	end

	local character = player.Character
	if character then
		ShopService.ApplyEffect(character, itemData)
	end

	return true, "OK"
end

BuyItemFunction.OnServerInvoke = function(player, itemId)
	print(string.format("DEBUG: ShopService received request from %s for %s", player.Name, itemId))
	return ShopService.ProcessPurchase(player, itemId)
end

return ShopService

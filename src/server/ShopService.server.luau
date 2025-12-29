-- src/server/ShopService.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(Shared:WaitForChild("ShopConfig"))

local Events = ReplicatedStorage:WaitForChild("Events")
local BuyItemFunction = Events:WaitForChild("BuyItem")

local function applyItemEffect(character, item)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local itemType = item.Type
	local value = item.Value or 0
	local now = os.time()

	if itemType == "Speed" then
		humanoid.WalkSpeed = value
	elseif itemType == "Jump" then
		humanoid.JumpPower = value
		humanoid.UseJumpPower = true
	elseif itemType == "Gravity" then
		-- Efecto de gravedad baja
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- Limpiar fuerza anterior si existe
			local oldForce = hrp:FindFirstChild("LowGravForce")
			if oldForce then oldForce:Destroy() end

			local force = Instance.new("BodyForce")
			force.Name = "LowGravForce"
			-- Value = 0.4 (Target Gravity). Uplift = 1 - 0.4 = 0.6
			force.Force = Vector3.new(0, hrp:GetMass() * workspace.Gravity * (1 - value), 0)
			force.Parent = hrp

			-- Duración 30s (Hardcoded por compatibilidad histórica/lógica anterior, o podría ser atributo)
			character:SetAttribute("Buff_Gravity_End", now + 30)
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
	elseif itemType == "Fly" then
		-- Fly
		local duration = value > 0 and value or 10
		character:SetAttribute("Buff_Fly_End", now + duration)
	elseif itemType == "DoubleJump" then
		-- Double Jump (Permanente hasta morir)
		character:SetAttribute("Buff_DoubleJump", true)
	elseif itemType == "Multiplier" then
		-- Multiplier
		local duration = 60 -- 1 minuto
		character:SetAttribute("PointMultiplier", value)
		character:SetAttribute("Buff_Multiplier_End", now + duration)
	end
end

local function onBuyItem(player, itemId)
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

	local leaderstats = player:FindFirstChild("leaderstats")
	local crStat = leaderstats and leaderstats:FindFirstChild("CR")

	if not crStat or crStat.Value < itemData.Price then
		return false, "Pobretón"
	end

	crStat.Value = crStat.Value - itemData.Price

	local character = player.Character
	if character then
		applyItemEffect(character, itemData)
	end

	return true, "OK"
end

BuyItemFunction.OnServerInvoke = onBuyItem

-- Loop para limpiar buffs expirados
task.spawn(function()
	while true do
		local now = os.time()
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if character then
				-- Check God Mode
				local godEnd = character:GetAttribute("Buff_God_End")
				if godEnd and now > godEnd then
					character:SetAttribute("Buff_God_End", nil)
					local ff = character:FindFirstChild("GodModeFF")
					if ff then ff:Destroy() end
				end

				-- Check Fly (Client handles mechanics, Server just cleans attribute)
				local flyEnd = character:GetAttribute("Buff_Fly_End")
				if flyEnd and now > flyEnd then
					character:SetAttribute("Buff_Fly_End", nil)
				end

				-- Check Multiplier
				local multEnd = character:GetAttribute("Buff_Multiplier_End")
				if multEnd and now > multEnd then
					character:SetAttribute("Buff_Multiplier_End", nil)
					character:SetAttribute("PointMultiplier", 1)
				end

				-- Check Gravity
				local gravEnd = character:GetAttribute("Buff_Gravity_End")
				if gravEnd and now > gravEnd then
					character:SetAttribute("Buff_Gravity_End", nil)
					local hrp = character:FindFirstChild("HumanoidRootPart")
					if hrp then
						local f = hrp:FindFirstChild("LowGravForce")
						if f then f:Destroy() end
					end
				end
			end
		end
		task.wait(0.5)
	end
end)

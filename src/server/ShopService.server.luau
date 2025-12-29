-- src/server/ShopService.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(Shared:WaitForChild("ShopConfig"))

local Events = ReplicatedStorage:WaitForChild("Events")
local BuyItemFunction = Events:WaitForChild("BuyItem")

local function applyItemEffect(character, itemData)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    local itemType = itemData.Type
    local value = itemData.Value

    if itemType == "Speed" then
        humanoid.WalkSpeed = value or 22
    elseif itemType == "Jump" then
        humanoid.JumpPower = value or 65
        humanoid.UseJumpPower = true 
    elseif itemType == "Gravity" then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Limpiar fuerza anterior si existe
            local existing = hrp:FindFirstChild("LowGravForce")
            if existing then existing:Destroy() end

            local force = Instance.new("BodyForce")
            force.Name = "LowGravForce"
            -- value es 0.4 (factor de gravedad deseada? o factor de fuerza?)
            -- Config original Value=0.4. Codigo original: force = Mass * Gravity * 0.4.
            -- Mantendremos la lógica original pero dinámica.
            force.Force = Vector3.new(0, hrp:GetMass() * workspace.Gravity * (value or 0.4), 0)
            force.Parent = hrp
        end
    elseif itemType == "DoubleJump" then
        character:SetAttribute("Buff_DoubleJump", true)
    elseif itemType == "Fly" then
        character:SetAttribute("Buff_Fly_End", os.time() + (value or 10))
    elseif itemType == "Protect" then
        character:SetAttribute("HasShield", true)
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(255, 0, 100)
        highlight.Name = "ShieldHighlight"
        highlight.Parent = character
    elseif itemType == "Heal" then
        humanoid.Health = humanoid.MaxHealth
    elseif itemType == "God" then
        local duration = value or 5
        character:SetAttribute("Buff_God_End", os.time() + duration)

        -- ForceField visual y protección física
        local ff = Instance.new("ForceField")
        ff.Name = "GodModeFF"
        ff.Visible = false -- Invisible según prompt
        ff.Parent = character
        Debris:AddItem(ff, duration)

    elseif itemType == "Multiplier" then
        -- Asumimos 60s si no hay duración explícita, prompt ejemplo dice 60.
        -- Config dice "(1m)" en nombre.
        local duration = 60
        character:SetAttribute("Buff_Multiplier_End", os.time() + duration)
        character:SetAttribute("PointMultiplier", value or 2)
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

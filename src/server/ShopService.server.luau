-- src/server/ShopService.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(Shared:WaitForChild("ShopConfig"))

local Events = ReplicatedStorage:WaitForChild("Events")
local BuyItemFunction = Events:WaitForChild("BuyItem")

local function applyItemEffect(character, itemType)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    if itemType == "Speed" then
        humanoid.WalkSpeed = humanoid.WalkSpeed + 8
    elseif itemType == "Jump" then
        humanoid.JumpPower = humanoid.JumpPower + 12
        humanoid.UseJumpPower = true 
    elseif itemType == "Gravity" then
        -- Efecto de gravedad baja
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local force = Instance.new("BodyForce")
            force.Name = "LowGravForce"
            force.Force = Vector3.new(0, hrp:GetMass() * workspace.Gravity * 0.4, 0)
            force.Parent = hrp
            task.delay(30, function() if force then force:Destroy() end end)
        end
    elseif itemType == "Protect" then
        character:SetAttribute("HasShield", true)
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(255, 0, 100)
        highlight.Parent = character
    elseif itemType == "Heal" then
        humanoid.Health = humanoid.MaxHealth
    elseif itemType == "Multiplier" then
        character:SetAttribute("PointMultiplier", 2)
        task.delay(60, function() character:SetAttribute("PointMultiplier", 1) end)
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
        applyItemEffect(character, itemData.Type)
    end

    return true, "OK"
end

BuyItemFunction.OnServerInvoke = onBuyItem

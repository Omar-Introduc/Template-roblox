local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CrystalConfig = require(ReplicatedStorage.Shared.CrystalConfig)
local TAG_NAME = "Crystal"

local function updateVisuals(part: BasePart)
    local life = part:GetAttribute("Life")
    local color = CrystalConfig.DurabilityColors[life]
    if color then
        part.Color = color
    end
end

local function setupCrystal(part: BasePart)
    if not part:GetAttribute("Life") then
        part:SetAttribute("Life", 5)
    end
    updateVisuals(part)

    part.Touched:Connect(function(hit)
        local humanoid = hit.Parent:FindFirstChild("Humanoid")
        if humanoid then
            if part:GetAttribute("IsCoolingDown") then
                return
            end

            part:SetAttribute("IsCoolingDown", true)

            local currentLife = part:GetAttribute("Life")
            local newLife = currentLife - 1
            part:SetAttribute("Life", newLife)

            if newLife <= 0 then
                part:Destroy()
            else
                updateVisuals(part)
                task.wait(CrystalConfig.DebounceTime)
                part:SetAttribute("IsCoolingDown", false)
            end
        end
    end)
end

-- Inicializar existentes y futuros
for _, part in pairs(CollectionService:GetTagged(TAG_NAME)) do
    setupCrystal(part)
end
CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(setupCrystal)

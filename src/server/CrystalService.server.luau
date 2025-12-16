local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CrystalConfig = require(ReplicatedStorage.Shared.CrystalConfig)
local TAG_NAME = "Crystal"

local function setupCrystal(part: BasePart)
    part.Color = CrystalConfig.Colors.Default

    part.Touched:Connect(function(hit)
        local humanoid = hit.Parent:FindFirstChild("Humanoid")
        if humanoid then
            print("Debug: Cristal tocado por " .. hit.Parent.Name)
            part.Color = CrystalConfig.Colors.Touched
        end
    end)
end

-- Inicializar existentes y futuros
for _, part in pairs(CollectionService:GetTagged(TAG_NAME)) do
    setupCrystal(part)
end
CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(setupCrystal)

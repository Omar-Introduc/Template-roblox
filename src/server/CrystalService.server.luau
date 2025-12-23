local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CrystalConfig = require(ReplicatedStorage.Shared.CrystalConfig)
local TAG_NAME = "Crystal"

-- Función auxiliar para crear el texto del contador sobre la parte
local function createCounter(part, value)
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Top -- El texto aparece en la cara de arriba
    surfaceGui.CanvasSize = Vector2.new(200, 200)
    surfaceGui.Adornee = part
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = tostring(value)
    textLabel.TextColor3 = Color3.new(0, 0, 0) -- Texto negro
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = surfaceGui
    
    surfaceGui.Parent = part
    return textLabel
end

local function setupCrystal(part: BasePart)
    -- Check if the part is in Workspace. If not (e.g., in ServerStorage/Templates), do not apply logic yet.
    if not part:IsDescendantOf(workspace) then
        return
    end

    part.Color = CrystalConfig.Colors.Default
    
    -- Variables locales para controlar esta plataforma específica
    local currentTouches = CrystalConfig.MaxTouches
    local isDebounce = false -- Para evitar que cuente muchos toques en un solo segundo
    
    -- Crear el contador visual
    local counterLabel = createCounter(part, currentTouches)

    part.Touched:Connect(function(hit)
        -- Verificar si fue un jugador y si no estamos en tiempo de espera
        local humanoid = hit.Parent:FindFirstChild("Humanoid")
        
        if humanoid and not isDebounce then
            isDebounce = true
            
            -- Lógica del golpe
            part.Color = CrystalConfig.Colors.Touched -- Cambia a Magenta
            
            -- Check for IgnoreTouches attribute
            if part:GetAttribute("IgnoreTouches") == true then
                 -- If ignored, just wait and reset color, NO destruction logic
                 task.wait(CrystalConfig.DebounceTime)
                 part.Color = CrystalConfig.Colors.Default -- Vuelve a Cyan
                 isDebounce = false
                 return
            end

            print("Debug: Cristal pisado! Restan: " .. (currentTouches - 1))

            currentTouches = currentTouches - 1
            counterLabel.Text = tostring(currentTouches) -- Actualizar el texto
            
            if currentTouches <= 0 then
                -- ¡SE ROMPE!
                task.wait(0.2) -- Pequeña pausa dramática
                part:Destroy() -- Elimina el objeto del juego
            else
                -- Si no se rompe, esperar y volver a la normalidad
                task.wait(CrystalConfig.DebounceTime)
                part.Color = CrystalConfig.Colors.Default -- Vuelve a Cyan
                isDebounce = false
            end
        end
    end)
end

-- Inicializar existentes y futuros
for _, part in pairs(CollectionService:GetTagged(TAG_NAME)) do
    setupCrystal(part)
end
CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(setupCrystal)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Configuración de la mecánica
local CONFIG = {
    COUNTDOWN_TIME = 3,
    FALL_DELAY = 2,
    RESET_DELAY = 5,
    GAP = 12, 
    TAG_PLATFORMA = "PlataformaCaida",
    
    -- CONFIGURACIÓN DE MOVIMIENTO
    AMPLITUD_MAXIMA = 10,
    VELOCIDAD_OSCILACION = 2 
}

local CentroGlobalZ = 0

if not workspace:GetAttribute("MapScanned") then
    workspace:GetAttributeChangedSignal("MapScanned"):Wait()
end

local estructuras = workspace:WaitForChild("Estructuras")
local p1_inicial = estructuras:WaitForChild("Plataforma_1", 10)
if p1_inicial then
    CentroGlobalZ = p1_inicial:GetPivot().Position.Z
end

local activatePlatformLogic 

-- Función de movimiento: Ajustada para evitar tirones (Snapping)
local function aplicarMovimientoSincronizado(platform, mainPart)
    if platform.Name == "Plataforma_1" then return end

    local attachment = mainPart:FindFirstChild("MoveAttachment") or Instance.new("Attachment")
    attachment.Name = "MoveAttachment"
    attachment.Parent = mainPart
    
    local alignPos = mainPart:FindFirstChild("PlatformAlign") or Instance.new("AlignPosition")
    alignPos.Name = "PlatformAlign"
    alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPos.Attachment0 = attachment
    alignPos.MaxForce = 1000000 
    -- Bajamos la Responsiveness para que el movimiento sea más elástico y no pegue tirones
    alignPos.Responsiveness = 15 
    alignPos.Enabled = true
    alignPos.Parent = mainPart

    local alignOri = mainPart:FindFirstChild("PlatformOri") or Instance.new("AlignOrientation")
    alignOri.Name = "PlatformOri"
    alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOri.Attachment0 = attachment
    alignOri.CFrame = mainPart.CFrame 
    alignOri.MaxTorque = 1000000 
    alignOri.Responsiveness = 200 
    alignOri.Enabled = true
    alignOri.Parent = mainPart

    mainPart.Anchored = false 

    task.spawn(function()
        local tiempo = 0
        local xOriginal = mainPart.Position.X
        local yOriginal = mainPart.Position.Y

        while mainPart and mainPart.Parent and alignPos.Enabled do
            local dt = task.wait()
            tiempo += dt
            
            local nuevoZ = CentroGlobalZ + (math.sin(tiempo * CONFIG.VELOCIDAD_OSCILACION) * CONFIG.AMPLITUD_MAXIMA)
            -- Usamos Position para el objetivo del AlignPosition
            alignPos.Position = Vector3.new(xOriginal, yOriginal, nuevoZ)
            
            if platform:GetAttribute("Triggered") == true and mainPart.Color == Color3.new(0,0,0) then
                break
            end
        end
        
        if alignPos then alignPos.Enabled = false end
        if alignOri then alignOri.Enabled = false end
    end)
end

local function resetMapProgress()
    if not estructuras then return end
    for _, objeto in ipairs(estructuras:GetChildren()) do
        if string.match(objeto.Name, "Plataforma_") and objeto.Name ~= "Plataforma_1" then
            objeto:Destroy()
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(0.1)
        resetMapProgress()
    end)
end)

local function createCountdown(parentPart)
    local bb = Instance.new("BillboardGui")
    bb.Name = "CountdownGui"
    bb.Size = UDim2.new(0, 100, 0, 100)
    bb.StudsOffset = Vector3.new(0, 5, 0)
    bb.AlwaysOnTop = true
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.new(1, 1, 1)
    text.Font = Enum.Font.FredokaOne
    text.TextScaled = true
    text.Text = tostring(CONFIG.COUNTDOWN_TIME)
    text.Parent = bb
    bb.Parent = parentPart
    return bb, text
end

local function spawnNext(currentPlatform)
    local currentNum = tonumber(string.match(currentPlatform.Name, "%d+")) or 1
    local nextNum = currentNum + 1
    local nextName = "Plataforma_" .. nextNum

    if estructuras:FindFirstChild(nextName) then return end

    local template = ServerStorage:FindFirstChild("PlataformaTemplate")
    if not template then return end

    local newPlatform = template:Clone()
    newPlatform.Name = nextName
    
    local incremento = 0.2 
    local distanciaCalculada = CONFIG.GAP + (nextNum * incremento)
    if distanciaCalculada > 22 then distanciaCalculada = 22 end

    local currentPivot = currentPlatform:GetPivot()
    -- IMPORTANTE: Generamos la plataforma un poco más lejos en Z para que no colisione al nacer
    local nuevaPosicion = Vector3.new(currentPivot.Position.X + distanciaCalculada, currentPivot.Position.Y, CentroGlobalZ)
    
    local rotacionPerfecta = template:GetPivot().Rotation
    newPlatform:PivotTo(CFrame.new(nuevaPosicion) * rotacionPerfecta)
    newPlatform.Parent = estructuras
end

activatePlatformLogic = function(platform)
    if not platform or platform.Name == "PlataformaTemplate" then return end

    local mainPart = platform:IsA("Model") and platform.PrimaryPart or platform
    if not mainPart or not mainPart:IsA("BasePart") then return end

    if not platform:GetAttribute("OriginalPosition") then
        platform:SetAttribute("OriginalPosition", mainPart.Position)
    end

    local oldAlign = mainPart:FindFirstChild("PlatformAlign")
    if oldAlign then oldAlign.Enabled = false end
    local oldOri = mainPart:FindFirstChild("PlatformOri")
    if oldOri then oldOri.Enabled = false end

    mainPart.Anchored = true 
    mainPart.CanCollide = true
    mainPart.Transparency = 0
    mainPart.AssemblyLinearVelocity = Vector3.zero
    mainPart.AssemblyAngularVelocity = Vector3.zero 
    
    local posBase = platform:GetAttribute("OriginalPosition")
    mainPart.Position = Vector3.new(posBase.X, posBase.Y, CentroGlobalZ)
    mainPart.Rotation = Vector3.new(0,0,0) 
    
    mainPart.Color = Color3.fromHex("#a3a3a3")
    platform:SetAttribute("Triggered", false)

    if platform.Name ~= "Plataforma_1" then
        aplicarMovimientoSincronizado(platform, mainPart)
    end

    local connection
    connection = mainPart.Touched:Connect(function(hit)
        if platform:GetAttribute("Triggered") then return end
        if not hit.Parent or not hit.Parent:FindFirstChild("Humanoid") then return end

        if platform.Name == "Plataforma_1" then
            spawnNext(platform)
            return 
        end

        platform:SetAttribute("Triggered", true)
        spawnNext(platform)

        local gui, label = createCountdown(mainPart)
        for i = CONFIG.COUNTDOWN_TIME, 1, -1 do
            label.Text = tostring(i)
            task.wait(1)
        end
        if gui then gui:Destroy() end

        local align = mainPart:FindFirstChild("PlatformAlign")
        if align then align.Enabled = false end 
        local ori = mainPart:FindFirstChild("PlatformOri")
        if ori then ori.Enabled = false end
        
        mainPart.Color = Color3.new(0, 0, 0)
        mainPart.Anchored = false 
        mainPart.CanCollide = false
        connection:Disconnect()

        task.delay(CONFIG.FALL_DELAY + CONFIG.RESET_DELAY, function()
            activatePlatformLogic(platform) 
        end)
    end)
end

for _, platform in ipairs(CollectionService:GetTagged(CONFIG.TAG_PLATFORMA)) do
    activatePlatformLogic(platform)
end

CollectionService:GetInstanceAddedSignal(CONFIG.TAG_PLATFORMA):Connect(function(instance)
    task.wait(0.1)
    activatePlatformLogic(instance)
end)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Configuración de la mecánica
local CONFIG = {
    COUNTDOWN_TIME = 3,
    FALL_DELAY = 2,
    RESET_DELAY = 5,
    PUNTOS_BASE = 1,
    
    -- DISTANCIA DINÁMICA AJUSTADA
    ESPACIO_ENTRE_BORDES = 5, -- Reducido de 8 a 5 para saltos más fáciles al inicio
    
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
local spawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
if spawnLocation then
    CentroGlobalZ = spawnLocation.Position.Z
else
    local p1_inicial = estructuras:WaitForChild("Plataforma_1", 10)
    if p1_inicial then
        CentroGlobalZ = p1_inicial:GetPivot().Position.Z
    end
end

local PointAwarded = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PointAwarded")

local activatePlatformLogic 

-- Función de movimiento sincronizado
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
            alignPos.Position = Vector3.new(xOriginal, yOriginal, nuevoZ)
            
            -- Solo se detiene el movimiento si se vuelve negra (pisada)
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
        elseif objeto.Name == "Plataforma_1" then
            -- Reiniciar estado de Plataforma_1 para permitir nuevos spawns
            objeto:SetAttribute("Triggered", false)
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
    local sg = Instance.new("SurfaceGui")
    sg.Name = "CountdownGui"
    sg.Face = Enum.NormalId.Top -- Se dibuja en la cara superior
    sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    sg.PixelsPerStud = 50
    sg.AlwaysOnTop = false -- Para que se sienta parte de la superficie
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.new(1, 1, 1)
    text.Font = Enum.Font.FredokaOne
    text.TextScaled = true
    text.Text = tostring(CONFIG.COUNTDOWN_TIME)
    text.Parent = sg
    sg.Parent = parentPart
    return sg, text
end

local function otorgarPuntos(player, platformName, position)
    local nPlataforma = tonumber(string.match(platformName, "%d+")) or 1
    local basePuntos = CONFIG.PUNTOS_BASE + (nPlataforma - 1)
    
    local multiplicador = 1
    if player.Character then
        multiplicador = player.Character:GetAttribute("PointMultiplier") or 1
    end
    
    local puntosAGanar = basePuntos * multiplicador
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local cr = leaderstats:FindFirstChild("CR")
        if cr then
            cr.Value += puntosAGanar
            -- Notificar al cliente para el feedback visual
            PointAwarded:FireClient(player, puntosAGanar, position)
        end
    end
end

local function spawnNext(currentPlatform)
    local currentNum = tonumber(string.match(currentPlatform.Name, "%d+")) or 1
    local nextNum = currentNum + 1
    local nextName = "Plataforma_" .. nextNum

    if estructuras:FindFirstChild(nextName) then return end

    local prefabs = ServerStorage:WaitForChild("Prefabs")
    local template = prefabs:FindFirstChild("PlataformaTemplate")
    if not template then return end

    local newPlatform = template:Clone()
    newPlatform.Name = nextName
    
    -- CALCULO DE DISTANCIA DINÁMICO
    local sizeX = template:IsA("Model") and template:GetExtentsSize().X or template.Size.X
    
    -- Dificultad progresiva suave
    local incrementoDificultad = math.min(nextNum * 0.1, 5) 
    local distanciaFinal = sizeX + CONFIG.ESPACIO_ENTRE_BORDES + incrementoDificultad

    local currentPivot = currentPlatform:GetPivot()
    local templatePivot = template:GetPivot()
    local nuevaPosicion = Vector3.new(currentPivot.Position.X + distanciaFinal, templatePivot.Position.Y, CentroGlobalZ)
    
    newPlatform:PivotTo(CFrame.new(nuevaPosicion) * templatePivot.Rotation)
    newPlatform.Parent = estructuras
end

activatePlatformLogic = function(platform)
    if not platform or platform.Name == "PlataformaTemplate" then return end
    if platform:GetAttribute("IsActive") then return end -- Evitar doble activación
    platform:SetAttribute("IsActive", true)

    local mainPart = platform:IsA("Model") and platform.PrimaryPart or platform
    if not mainPart or not mainPart:IsA("BasePart") then return end

    if not platform:GetAttribute("OriginalPivot") then
        platform:SetAttribute("OriginalPivot", platform:GetPivot())
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
    
    local pivotBase = platform:GetAttribute("OriginalPivot")
    platform:PivotTo(pivotBase)
    
    -- Se ELIMINÓ la línea que cambiaba el color a gris (#a3a3a3)
    platform:SetAttribute("Triggered", false)

    if platform.Name ~= "Plataforma_1" then
        aplicarMovimientoSincronizado(platform, mainPart)
    end
    local connection
    connection = mainPart.Touched:Connect(function(hit)
        if platform:GetAttribute("Triggered") then return end
        local character = hit.Parent
        local humanoid = character and character:FindFirstChild("Humanoid")
        if not humanoid then return end

        local player = Players:GetPlayerFromCharacter(character)
        if not player then return end

        -- Marcar como pisada para activar spawnNext y countdown
        platform:SetAttribute("Triggered", true)
        spawnNext(platform)

        -- INICIO DE BUCLE DE PUNTOS CONTINUOS (Seguro)
        task.spawn(function()
            while humanoid and humanoid.Parent and mainPart and mainPart.Parent do
                -- Verificación segura de FloorPart (evita el error 'not a valid member')
                local success, currentFloor = pcall(function() return humanoid.FloorPart end)
                if not success or currentFloor ~= mainPart then break end
                
                otorgarPuntos(player, platform.Name, mainPart.Position)
                task.wait(0.5)
            end
        end)

        if platform.Name == "Plataforma_1" then
            return -- Plataforma inicial no cae
        end

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
        
        -- Único cambio de color: Negro al activarse la caída
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
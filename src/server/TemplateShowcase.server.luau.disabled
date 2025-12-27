--[[
    🎨 Template Showcase System (Exhibition Version)
    Responsabilidad: Visualizar todos los modelos cargados en una fila organizada y BIEN APOYADOS en el suelo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ROW_SPACING_GAP = 15 
local START_POSITION = Vector3.new(0, 0, 0) 
local ROW_Z_POS = 10 -- Mantener los assets a 10 studs de distancia en Z

-- Configuración de ajustes específicos por Asset name (USAR MINÚSCULAS)
local ASSET_ADJUSTMENTS = {
    ["cueva"] = {
        ManualPosition = true, -- No mover, no rotar, dejar tal cual viene del asset
        Beautify = true
    },
    ["carro"] = {
        YOffset = 0,
        Beautify = true
    },
    ["lobby"] = {
        YOffset = 0,
        ExtraSpacing = 70,
        Beautify = true 
    }
}

-- Función para aplicar "texturas específicas" y mejorar el acabado visual basándose en la paleta Three.js
local function beautifyModel(model)
    print("🎨 Auditando jerarquía completa de: " .. model.Name)
    
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            -- LIMPIEZA TOTAL: Borramos cualquier rastro de texturas de Blender
            if part:IsA("MeshPart") then
                part.TextureID = "" 
            end
            local sa = part:FindFirstChildOfClass("SurfaceAppearance")
            if sa then sa:Destroy() end

            local name = part.Name:lower()
            local applied = false
            local category = ""

            -- --- PALETA HIERÁRQUICA (ES/EN) ---
            
            -- 1. Plataformas y Suelos (Gris Oscuro - #444444)
            if name:find("suelo") or name:find("piso") or name:find("floor") or name:find("base") or 
               name:find("plat") or name:find("cimiento") or name:find("deck") or 
               (name:find("mesh") and (part.Size.X > 5 or part.Size.Z > 5)) then
                part.Color = Color3.fromHex("#444444")
                part.Material = Enum.Material.Concrete
                category = "Plataforma/Suelo"
                applied = true
            
            -- 2. Rocas y Paredes de Piedra (Gris Carbón - #2a2a2a)
            elseif name:find("rock") or name:find("roc") or name:find("piedra") or name:find("stone") or 
                   name:find("montaña") or name:find("pared") or name:find("muro") then
                part.Color = Color3.fromHex("#2a2a2a")
                part.Material = Enum.Material.Basalt
                category = "Roca/Pared"
                applied = true
            
            -- 3. Madera y Columnas (Marrón Café - #5D4037)
            elseif name:find("wood") or name:find("madera") or name:find("tronc") or name:find("viga") or 
                   name:find("valla") or name:find("post") or name:find("pilar") or name:find("columna") or 
                   name:find("palos") or name:find("barandilla") or name:find("puente") or name:find("plank") then
                part.Color = Color3.fromHex("#5D4037")
                part.Material = Enum.Material.Wood
                category = "Madera/Pilar"
                applied = true
            
            -- 4. Cartel y Letreros (Fondo: #D7CCC8 | Borde: #3E2723)
            elseif name:find("sign") or name:find("cartel") or name:find("letrero") or name:find("signo") or 
                   name:find("board") or name:find("tablon") then
                if name:find("border") or name:find("frame") or name:find("borde") then
                    part.Color = Color3.fromHex("#3E2723")
                    part.Material = Enum.Material.SmoothPlastic
                else
                    part.Color = Color3.fromHex("#D7CCC8")
                    part.Material = Enum.Material.Fabric
                end
                category = "Cartel/Letrero"
                applied = true
                
            -- 5. Cristales o Ventanas (Cian UI - #00ccff)
            elseif name:find("glass") or name:find("ventan") or name:find("window") or 
                   name:find("cristal") or name:find("vidrio") then
                part.Color = Color3.fromHex("#00ccff")
                part.Material = Enum.Material.Glass
                part.Transparency = 0.4
                category = "Cristal/Ventana"
                applied = true
            
            -- 6. Luces y Antorchas
            elseif name:find("light") or name:find("luz") or name:find("neon") or name:find("lamp") or 
                   name:find("foco") or name:find("antorcha") or name:find("farola") then
                part.Color = Color3.fromHex("#ffffff")
                part.Material = Enum.Material.Neon
                category = "Luz/Neon"
                applied = true
            end

            -- Log de auditoría para el usuario
            if applied then
                print("   ✅ [" .. category .. "] " .. part.Name .. " -> Estilizado correctamente.")
            else
                -- FALLBACK: Gris industrial si no se reconoce
                part.Color = Color3.fromHex("#888888")
                part.Material = Enum.Material.SmoothPlastic
                print("   ⚠️ [Desconocido] " .. part.Name .. " -> Usando gris por defecto.")
            end
        end
    end
end

local function createNameTag(model, name)
	local bbGui = Instance.new("BillboardGui")
	bbGui.Name = "NameTag"
	bbGui.Size = UDim2.new(12, 0, 3, 0) 
	bbGui.StudsOffset = Vector3.new(0, 8, 0)
	bbGui.AlwaysOnTop = false
	bbGui.MaxDistance = 150

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = name
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.5
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Parent = bbGui

	bbGui.Parent = model
    
    if model:IsA("Model") and model.PrimaryPart then
        bbGui.Adornee = model.PrimaryPart
    elseif model:IsA("BasePart") then
        bbGui.Adornee = model
    end
end

local function anchorModel(model)
    if model:IsA("Model") then
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.Anchored = true
            end
        end
    elseif model:IsA("BasePart") then
        model.Anchored = true
    end
end

local function runShowcase()
    local JUMP_GAP = 12 -- Distancia necesaria para saltar
    print("⏳ Generando Nivel 1 con saltos y Lobby...")
    
    -- 1. Limpieza total
    local map = Workspace:FindFirstChild("Map_Geometry")
    if map then map:Destroy() end
    local gallery = Workspace:FindFirstChild("Exhibition_Gallery")
    if gallery then gallery:Destroy() end

    -- 2. Crear Contenedores
    map = Instance.new("Model")
    map.Name = "Map_Geometry"
    map.Parent = Workspace

    gallery = Instance.new("Model")
    gallery.Name = "Exhibition_Gallery"
    gallery.Parent = Workspace

    local templates = ReplicatedStorage:WaitForChild("Templates", 30)
    if not templates then warn("❌ No se encontró Templates.") return end
    if not templates:GetAttribute("PrefabReady") then
        templates:GetAttributeChangedSignal("PrefabReady"):Wait()
    end

    -- --- 3. POSICIONAR LOBBY ---
    local lobbyTemplate = templates:FindFirstChild("Lobby")
    local currentX = 0
    local zPos = ROW_Z_POS or 10

    if lobbyTemplate then
        print("🏠 Instanciando Lobby en el origen...")
        local lobby = lobbyTemplate:Clone()
        lobby.Name = "Main_Lobby"
        lobby.Parent = map
        
        local adj = ASSET_ADJUSTMENTS["lobby"] or {}
        beautifyModel(lobby)
        anchorModel(lobby)
        
        -- Centrar el Lobby en el origen
        lobby:MoveTo(Vector3.new(0, START_POSITION.Y + (adj.YOffset or 0), 0))
        
        -- Crear Spawn justo en el centro del Lobby (encima del piso)
        local spawn = Instance.new("SpawnLocation")
        spawn.Name = "LobbySpawn"
        spawn.Size = Vector3.new(10, 1, 10)
        spawn.CFrame = CFrame.new(0, 5, 0) -- Aparecer dentro
        spawn.Anchored = true
        spawn.Transparency = 1 
        spawn.CanCollide = false
        spawn.Parent = lobby

        local _, size = lobby:GetBoundingBox()
        -- El camino empieza AL FINAL del lobby + un pequeño gap inicial
        currentX = (size.X / 2) + JUMP_GAP
        createNameTag(lobby, "Lobby de Inicio")
    else
        warn("⚠️ No se encontró el asset 'Lobby' en Templates.")
    end

    -- --- 4. GENERAR NIVEL 1 (Con Saltos) ---
    local p1Template = templates:FindFirstChild("Plataforma_Level1")
    if p1Template then
        local levelFolder = Instance.new("Folder")
        levelFolder.Name = "Level_1"
        levelFolder.Parent = map

        print("🛠️ Generando 5 saltos nivel 1...")
        for i = 1, 5 do
            local p1 = p1Template:Clone()
            p1.Name = "Plataforma_Salto_" .. i
            p1.Parent = levelFolder
            
            beautifyModel(p1)
            anchorModel(p1)
            
            local _, size = p1:GetBoundingBox()
            local targetX = currentX + (size.X / 2)
            
            -- Posicionar con el gap de salto
            p1:MoveTo(Vector3.new(targetX, START_POSITION.Y, 0))
            
            -- Preparar el siguiente X dejando el hueco (distancia de plataforma + distancia de salto)
            currentX = targetX + (size.X / 2) + JUMP_GAP
            createNameTag(p1, "Salto " .. i)
        end
    else
        warn("⚠️ No se encontró 'Plataforma_Level1' para generar el nivel.")
    end

    -- --- 5. ZONA DE EXHIBICIÓN (Fuera del camino principal) ---
    -- Alineamos el resto de assets en una fila separada
    currentX = 0 
    
    for _, original in ipairs(templates:GetChildren()) do
        if original.Name == "Lobby" or original.Name == "Plataforma_Level1" then continue end
        if not (original:IsA("Model") or original:IsA("BasePart")) then continue end

        local adj = ASSET_ADJUSTMENTS[original.Name:lower()] or {}
        local clone = original:Clone()
        clone.Name = "Exhibicion_" .. original.Name
        clone.Parent = gallery
        
        if not adj.ManualPosition then clone:PivotTo(CFrame.new(0, 0, 0)) end
        
        local scale = adj.Scale or 1
        if scale ~= 1 then
            if clone:IsA("Model") then clone:ScaleTo(scale)
            elseif clone:IsA("BasePart") then clone.Size = clone.Size * scale end
        end

        if adj.Beautify ~= false then beautifyModel(clone) end
        anchorModel(clone)

        if not adj.ManualPosition then
            local _, size = clone:GetBoundingBox()
            local targetX = currentX + (size.X / 2)
            clone:MoveTo(Vector3.new(targetX, START_POSITION.Y + (adj.YOffset or 0), zPos))
            currentX = currentX + size.X + ROW_SPACING_GAP
        end
        
        createNameTag(clone, original.Name)
    end

    print("✨ Nivel 1 listo para saltar. Lobby centrado en origen.")
end

task.spawn(runShowcase)

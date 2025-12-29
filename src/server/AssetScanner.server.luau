-- src/server/AssetScanner.server.luau
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MapManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MapManager"))

local function scanMap()
    print("🔍 [AssetScanner] Iniciando escaneo con nueva ruta de Prefabs...")

    -- 1. Referencia a las carpetas
    local estructuras = workspace:WaitForChild("Estructuras", 10)
    
    -- MODIFICACIÓN: Buscamos primero la carpeta 'Prefabs' creada por Rojo
    local carpetaPrefabs = ServerStorage:WaitForChild("Prefabs", 10)
    local template = nil
    
    if carpetaPrefabs then
        -- Buscamos el template dentro de la carpeta Prefabs
        template = carpetaPrefabs:FindFirstChild("PlataformaTemplate")
    end

    -- 2. Lógica para la Plataforma_1
    local marcador = estructuras and estructuras:FindFirstChild("SpawnPlataforma_1")
    
    if marcador and template then
        -- Clonamos el molde (Prefab)
        local p1 = template:Clone()
        p1.Name = "Plataforma_1"
        
        -- Usamos GetPivot para copiar la posición EXACTA del marcador
        p1:PivotTo(marcador:GetPivot())
        
        p1.Parent = estructuras
        
        -- Registramos en el MapManager
        MapManager.AddPlatform(p1)
        
        -- Eliminamos el marcador de Studio
        marcador:Destroy() 
        print("✅ Plataforma_1 generada exitosamente desde ServerStorage/Prefabs.")
    else
        warn("⚠️ Error Crítico: No se encontró 'SpawnPlataforma_1' o 'PlataformaTemplate' en la carpeta Prefabs.")
    end

    -- 3. Vincular otras plataformas con Tag
    local plataformasEtiquetadas = CollectionService:GetTagged("PlataformaCaida")
    for _, objeto in ipairs(plataformasEtiquetadas) do
        if objeto.Name ~= "Plataforma_1" and not objeto:IsDescendantOf(ServerStorage) then
            MapManager.AddPlatform(objeto)
            print("✅ Plataforma adicional detectada: " .. objeto.Name)
        end
    end

    -- 4. Vincular Lobby y Tiendas (Manual)
    local lobby = CollectionService:GetTagged("LobbyTag")[1]
    if lobby then
        MapManager.SetLobby(lobby)
        print("✅ [Scanner] Lobby vinculado.")
    end

    local shopsFound = {}
    -- Buscar por TAG
    local categoryTags = {
        ["TiendaTag_Movement"] = "Movement",
        ["TiendaTag_Aero"] = "Aero",
        ["TiendaTag_Survival"] = "Survival",
        ["TiendaTag_Economy"] = "Economy"
    }

    local allShopTags = {"TiendaTag"}
    for tag, _ in pairs(categoryTags) do table.insert(allShopTags, tag) end

    for _, tag in ipairs(allShopTags) do
        for _, t in ipairs(CollectionService:GetTagged(tag)) do
            if t:IsDescendantOf(workspace) and not table.find(shopsFound, t) then
                print("🛍️ [Scanner] Tienda detectada por Tag: " .. t.Name .. " (Tag: " .. tag .. ")")
                
                -- Asignar categoría basada en el tag
                local category = categoryTags[tag]
                if category then
                    t:SetAttribute("Category", category)
                    print("📌 Categoría asignada: " .. category)
                end
                
                -- IMPORTANT: Client looks for "TiendaTag", so we MUST add it if searching by specific tag
                if not CollectionService:HasTag(t, "TiendaTag") then
                     CollectionService:AddTag(t, "TiendaTag")
                end

                table.insert(shopsFound, t)
                
                -- ESTÉTICA "VIDRIO" (Solo propiedades visuales)
                local mainPart = t:IsA("BasePart") and t or (t:FindFirstChild("Display", true) or t.PrimaryPart or t:FindFirstChildWhichIsA("BasePart", true))
                if mainPart then
                    mainPart.Material = Enum.Material.Glass
                    mainPart.Transparency = 0.8 -- Más transparente para efecto vidrio fino
                    mainPart.CastShadow = false
                    
                    -- Borde Neón Estético
                    local selection = mainPart:FindFirstChild("NeonBorder") or Instance.new("SelectionBox")
                    selection.Name = "NeonBorder"
                    selection.Adornee = mainPart
                    selection.Color3 = Color3.fromRGB(0, 255, 255)
                    selection.LineThickness = 0.02
                    selection.Transparency = 0.5
                    selection.Parent = mainPart
                end
            end
        end
    end
    
    -- Fallback: Buscar por Nombre si no hay Tags
    if #shopsFound == 0 then
        local t = workspace:FindFirstChild("ShopBoard", true) or workspace:FindFirstChild("TiendaVisual", true)
        if t then
            print("🛍️ [Scanner] Tienda detectada por Nombre: " .. t.Name)
            CollectionService:AddTag(t, "TiendaTag")
            table.insert(shopsFound, t)
        end
    end

    if #shopsFound > 0 then
        for _, shop in ipairs(shopsFound) do
            MapManager.AddShopBoard(shop)
        end
        print("🚀 [Scanner] " .. #shopsFound .. " tienda(s) vinculada(s) exitosamente.")
    else
        warn("⚠️ [Scanner] No se detectaron tiendas. Asegúrate de poner el Tag 'TiendaTag' o el nombre 'ShopBoard'.")
    end

    -- 5. Notificar al GameLoop
    workspace:SetAttribute("MapScanned", true)
    print("🚀 [AssetScanner] Escaneo finalizado.")
end

scanMap()
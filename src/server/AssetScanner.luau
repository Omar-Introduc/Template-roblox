--!strict
local AssetScanner = {}
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MapManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MapManager"))

function AssetScanner.Init()
    print("🔍 [AssetScanner] Iniciando escaneo con lógica consolidada...")

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
        -- Evitar warn si ya existe la plataforma (re-escaneo manual por ejemplo)
        if not estructuras:FindFirstChild("Plataforma_1") then
            warn("⚠️ Error Crítico: No se encontró 'SpawnPlataforma_1' o 'PlataformaTemplate' en la carpeta Prefabs.")
        end
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
    local lobbyList = CollectionService:GetTagged("LobbyTag")
    local lobby = lobbyList[1]
    if lobby then
        MapManager.SetLobby(lobby)
        print("✅ [Scanner] Lobby vinculado.")
    end

    local shopsFoundCount = 0
    -- Buscar por TAG
    local categoryTags = {
        ["TiendaTag_Movement"] = "Movement",
        ["TiendaTag_Aero"] = "Aero",
        ["TiendaTag_Survival"] = "Survival",
        ["TiendaTag_Economy"] = "Economy",
        ["TiendaTag_Robux"] = "Robux"
    }

    local allShopTags = {"TiendaTag"}
    for tag, _ in pairs(categoryTags) do table.insert(allShopTags, tag) end

    -- Developers Note: Builders is a peer to script.Parent if AssetScanner is in src/server
    local BuildersFolder = script.Parent:WaitForChild("Builders", 5)
    local ShopBuilderRobux = BuildersFolder and require(BuildersFolder:WaitForChild("ShopBuilder_Robux"))
    local ShopBuilderStandard = BuildersFolder and require(BuildersFolder:WaitForChild("ShopBuilder_Standard"))

    local processedShops = {}

    for _, tag in ipairs(allShopTags) do
        for _, t in ipairs(CollectionService:GetTagged(tag)) do
            if t:IsDescendantOf(workspace) and not processedShops[t] then
                processedShops[t] = true
                
                -- Asignar categoría basada en el tag
                local category = categoryTags[tag]
                if category then
                    t:SetAttribute("Category", category)
                end
                
                -- Asegurar Tag base
                if not CollectionService:HasTag(t, "TiendaTag") then
                     CollectionService:AddTag(t, "TiendaTag")
                end

                shopsFoundCount += 1
                MapManager.AddShopBoard(t)
                
                -- LÓGICA DE CONSTRUCCIÓN SEGÚN CATEGORÍA
                local mainPart = t:IsA("BasePart") and t or (t:FindFirstChild("Display", true) or t.PrimaryPart or t:FindFirstChildWhichIsA("BasePart", true))
                if mainPart then
                    if category == "Robux" and ShopBuilderRobux then
                        ShopBuilderRobux.BuildFuturisticKiosk(mainPart)
                    elseif ShopBuilderStandard then
                        ShopBuilderStandard.BuildStandardPanel(mainPart)
                    end
                end
            end
        end
    end
    
    -- Fallback: Buscar por Nombre si no hay Tags
    if shopsFoundCount == 0 then
        local t = workspace:FindFirstChild("ShopBoard", true) or workspace:FindFirstChild("TiendaVisual", true)
        if t then
            print("🛍️ [Scanner] Tienda detectada por Nombre: " .. t.Name)
            CollectionService:AddTag(t, "TiendaTag")
            MapManager.AddShopBoard(t)
            shopsFoundCount += 1
        end
    end

    if shopsFoundCount > 0 then
        print("🚀 [Scanner] " .. shopsFoundCount .. " tienda(s) vinculada(s) exitosamente.")
    else
        warn("⚠️ [Scanner] No se detectaron tiendas. Asegúrate de poner el Tag 'TiendaTag' o el nombre 'ShopBoard'.")
    end

    -- 5. Notificar al GameLoop
    workspace:SetAttribute("MapScanned", true)
    print("🚀 [AssetScanner] Escaneo finalizado.")
end

return AssetScanner

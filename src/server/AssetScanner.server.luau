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

    -- 4. Vincular Lobby y Tienda
    local lobby = CollectionService:GetTagged("LobbyTag")[1]
    if lobby then
        MapManager.SetLobby(lobby)
        print("✅ Lobby vinculado.")
    end

    local tienda = CollectionService:GetTagged("TiendaTag")[1]
    if tienda then
        MapManager.SetShopBoard(tienda)
        print("✅ Tienda vinculada.")
    end

    -- 5. Notificar al GameLoop
    workspace:SetAttribute("MapScanned", true)
    print("🚀 [AssetScanner] Escaneo finalizado.")
end

scanMap()
-- src/server/AssetScanner.server.luau
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MapManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MapManager"))

local function scanMap()
    print("🔍 [AssetScanner] Iniciando escaneo profesional con Orientación 0...")

    -- Usamos WaitForChild para dar tiempo a que las carpetas carguen en el servidor
    local estructuras = workspace:WaitForChild("Estructuras", 10)
    local template = ServerStorage:WaitForChild("PlataformaTemplate", 10)

    -- 1. Lógica para la Plataforma_1 (Posicionamiento Manual + Apariencia del Template)
    local marcador = estructuras:FindFirstChild("SpawnPlataforma_1")
    
    if marcador and template then
        -- Clonamos el molde (Prefab)
        local p1 = template:Clone()
        p1.Name = "Plataforma_1"
        
        -- IMPORTANTE: Usamos GetPivot para copiar la posición EXACTA del marcador
        -- Como tu orientación es 0, esto lo pondrá perfectamente alineado.
        p1:PivotTo(marcador:GetPivot())
        
        p1.Parent = estructuras
        
        -- Registramos en el MapManager para que el GameLoop la reconozca
        MapManager.AddPlatform(p1)
        
        -- Eliminamos el marcador visual/invisible de Studio
        marcador:Destroy() 
        print("✅ Plataforma_1 generada exitosamente desde el Template.")
    else
        warn("⚠️ Error Crítico: No se encontró 'SpawnPlataforma_1' en Estructuras o 'PlataformaTemplate' en ServerStorage.")
    end

    -- 2. Vincular otras plataformas que ya tengan el Tag (por si hay más manuales)
    local plataformasEtiquetadas = CollectionService:GetTagged("PlataformaCaida")
    for _, objeto in ipairs(plataformasEtiquetadas) do
        -- No duplicamos la que acabamos de crear arriba
        if objeto.Name ~= "Plataforma_1" and objeto.Parent ~= ServerStorage then
            MapManager.AddPlatform(objeto)
            print("✅ Plataforma adicional detectada: " .. objeto.Name)
        end
    end

    -- 3. Vincular Lobby y Tienda mediante Tags profesionales
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

    -- 4. Notificar al GameLoop que puede empezar
    workspace:SetAttribute("MapScanned", true)
    print("🚀 [AssetScanner] Escaneo y generación inicial finalizados.")
end

-- Ejecutamos la función
scanMap()
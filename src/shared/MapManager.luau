-- src/shared/MapManager.luau
local MapManager = {}

MapManager.References = {
    Lobby = nil,
    ShopBoard = nil,
    Platforms = {}, 
}

-- Guardar el Lobby
function MapManager.SetLobby(obj)
    MapManager.References.Lobby = obj
end

-- Guardar la Tienda
function MapManager.SetShopBoard(obj)
    MapManager.References.ShopBoard = obj
end

-- Añadir plataforma y mantener el orden numérico por nombre
function MapManager.AddPlatform(obj)
    if not table.find(MapManager.References.Platforms, obj) then
        table.insert(MapManager.References.Platforms, obj)
        table.sort(MapManager.References.Platforms, function(a, b)
            local numA = tonumber(string.match(a.Name, "%d+")) or 0
            local numB = tonumber(string.match(b.Name, "%d+")) or 0
            return numA < numB
        end)
    end
end

function MapManager.GetAllPlatforms()
    return MapManager.References.Platforms
end

return MapManager
-- src/shared/MapManager.luau
-- This module acts as the central registry for the static map.
-- It is populated by the server-side AssetScanner and read by GameLoop.

local MapManager = {}
MapManager.References = {
    Lobby = nil,
    ShopBoard = nil,
    Platforms = {}, -- Ordered list of platforms or map by name
    Checkpoints = {}
}

-- Since this is a shared module, the server writes to it, but the client
-- receives a fresh copy. We only need the Server to populate it for the Server scripts.
-- For Client, it would need to scan itself or use ObjectValues/Attributes if we wanted sync.
-- However, given the instructions, the scanner runs on Server. GameLoop runs on Server.
-- ShopUI runs on Client and needs to find ShopBoard.

function MapManager.SetLobby(lobbyPart)
    MapManager.References.Lobby = lobbyPart
end

function MapManager.SetShopBoard(shopPart)
    MapManager.References.ShopBoard = shopPart
end

function MapManager.AddPlatform(platformPart)
    table.insert(MapManager.References.Platforms, platformPart)
    -- Sort platforms by name number (e.g. Plataforma_1, Plataforma_2) just in case
    table.sort(MapManager.References.Platforms, function(a, b)
        local numA = tonumber(string.match(a.Name, "%d+")) or 0
        local numB = tonumber(string.match(b.Name, "%d+")) or 0
        return numA < numB
    end)
end

function MapManager.GetPlatform(index)
    return MapManager.References.Platforms[index]
end

function MapManager.GetAllPlatforms()
    return MapManager.References.Platforms
end

return MapManager

--[[
    🏛️ Lobby System - Template Showcase Mode

    Responsabilidad: Generar el área de visualización (Lobby) simple y plana.

    Autor: Jules
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- Configuración Centralizada
local CONFIG = {
	LobbyName = "Lobby",
	Size = Vector3.new(1000, 2, 500), -- Muy amplio para visualizar muchas plantillas
	Position = Vector3.new(0, -1, 0), -- Piso en Y=0 (superficie)
	Color = BrickColor.new("Medium stone grey"),
	Material = Enum.Material.SmoothPlastic
}

local function setupLighting()
    -- Reset to reasonable defaults for visualization
    Lighting.ClockTime = 14 -- 2 PM, good lighting
    Lighting.Brightness = 2
    Lighting.GlobalShadows = true
    Lighting.Ambient = Color3.fromRGB(120, 120, 120)
    Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 120)

    -- Limpiar efectos
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("PostEffect") or child:IsA("Sky") or child:IsA("Atmosphere") then
            child:Destroy()
        end
    end
end

local function createLobby()
	print("🏗️ Generando Lobby para Visualización...")
	
    -- Limpieza
	local oldLobby = Workspace:FindFirstChild(CONFIG.LobbyName)
	if oldLobby then oldLobby:Destroy() end

    -- Limpiar otros posibles objetos antiguos
    local objectsToRemove = {"LobbyIsland", "Baseplate", "DeadlyVoid", "Decorations"}
    for _, name in ipairs(objectsToRemove) do
        local obj = Workspace:FindFirstChild(name)
        if obj then obj:Destroy() end
    end

	setupLighting()

	-- Suelo Principal
	local floor = Instance.new("Part")
	floor.Name = CONFIG.LobbyName
	floor.Size = CONFIG.Size
	floor.Position = CONFIG.Position
	floor.Anchored = true
	floor.BrickColor = CONFIG.Color
	floor.Material = CONFIG.Material
	floor.Parent = Workspace

	-- Spawn Point
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(12, 1, 12)
    -- Posicionar spawn un poco elevado y atras para ver las plantillas enfrente
	spawn.Position = Vector3.new(0, 1, -50)
	spawn.Transparency = 0
	spawn.CanCollide = false
	spawn.Anchored = true
	spawn.Parent = Workspace

	print("✅ Lobby generado exitosamente.")
	return floor
end

createLobby()

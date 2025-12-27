--[[
    🏭 PrefabFactory - Asset Management System (Exhibition Version)

    Responsabilidad: Cargar los assets desde la carpeta 'asset' y organizarlos en 'Templates'.
    Elimina toda la lógica de parkour y generación de islas.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TEMPLATES_NAME = "Templates"

local function setupFolders()
	print("🏭 PrefabFactory: Inicializando carpeta de Templates...")

	local root = ReplicatedStorage:FindFirstChild(TEMPLATES_NAME)
	if root then
        root:ClearAllChildren()
    else
		root = Instance.new("Folder")
		root.Name = TEMPLATES_NAME
		root.Parent = ReplicatedStorage
	end

	return root
end

local function loadAssets(templatesRoot)
	local assetStorage = ReplicatedStorage:FindFirstChild("asset")
	if not assetStorage then
		warn("⚠️ PrefabFactory: Carpeta 'asset' no encontrada.")
		return
	end
	
    local assetsFound = assetStorage:GetChildren()
    print("📦 Cargando " .. #assetsFound .. " assets...")

	for _, sourceObj in ipairs(assetsFound) do
        local clone = sourceObj:Clone()
        -- Quitar extensiones si las tienen en el nombre
        clone.Name = sourceObj.Name:gsub("%.rbxm$", ""):gsub("%.rbxmx$", "")
        clone.Parent = templatesRoot
        print("   > Asset '" .. clone.Name .. "' cargado.")
	end
end

-- Ejecución principal
local templatesRoot = setupFolders()
loadAssets(templatesRoot)

-- Señal de finalización
templatesRoot:SetAttribute("PrefabReady", true)

print("✅ PrefabFactory: Sistema de Exhibition listo.")

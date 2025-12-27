--[[
    🏭 PrefabFactory - Asset Management System (Exhibition Version)

    Responsabilidad: Cargar los assets desde la carpeta 'asset' y organizarlos en 'Templates'.
    Escaneo recursivo para encontrar archivos en subcarpetas.
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

	print("📦 Iniciando escaneo recursivo de assets...")

	local scanFolder
	scanFolder = function(folder)
		for _, item in ipairs(folder:GetChildren()) do
			if item:IsA("Folder") or item:IsA("Configuration") then
				print("   [FOLDER] Entrando a: " .. item.Name)
				scanFolder(item)
			elseif item:IsA("Model") or item:IsA("BasePart") then
				-- Usamos pcall por si hay problemas de permisos o Archivable
				local status, clone = pcall(function()
					return item:Clone()
				end)

				if status and clone then
					-- Limpiar nombre de extensiones
					local cleanName = item.Name:gsub("%.rbxm$", ""):gsub("%.rbxmx$", "")
					clone.Name = cleanName
					clone.Parent = templatesRoot
					print("      ✅ Asset '" .. cleanName .. "' cargado correctamente.")
				else
					warn("      ❌ Error al clonar el objeto: " .. item.Name)
				end
			end
		end
	end

	scanFolder(assetStorage)
end

-- Ejecución principal
local templatesRoot = setupFolders()
loadAssets(templatesRoot)

-- Señal de finalización para otros scripts
templatesRoot:SetAttribute("PrefabReady", true)

print("✅ PrefabFactory: Proceso finalizado con éxito.")

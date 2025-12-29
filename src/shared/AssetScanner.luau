--!strict
local AssetScanner = {}
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- We assume MapManager is available in ReplicatedStorage/Shared
-- If not available immediately, we might need to wait, but this is server side init.
local MapManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MapManager"))

function AssetScanner.Init()
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
		-- Warning only if we expected it (sometimes it might be already there)
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
	local lobby = CollectionService:GetTagged("LobbyTag")[1]
	if lobby then
		MapManager.SetLobby(lobby)
		print("✅ [Scanner] Lobby vinculado.")
	end

	-- Buscar por TAG
	local shopsFound = 0
	for _, t in ipairs(CollectionService:GetTagged("TiendaTag")) do
		if t:IsDescendantOf(workspace) then
			print("🛍️ [Scanner] Tienda detectada por Tag: " .. t.Name)
			MapManager.AddShopBoard(t)
			shopsFound += 1

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

	-- Fallback: Buscar por Nombre si no hay Tags
	if shopsFound == 0 then
		local t = workspace:FindFirstChild("ShopBoard", true) or workspace:FindFirstChild("TiendaVisual", true)
		if t then
			print("🛍️ [Scanner] Tienda detectada por Nombre: " .. t.Name)
			CollectionService:AddTag(t, "TiendaTag")
			MapManager.AddShopBoard(t)
			shopsFound += 1
		end
	end

	if shopsFound > 0 then
		print("🚀 [Scanner] " .. shopsFound .. " tienda(s) vinculada(s) exitosamente.")
	else
		warn("⚠️ [Scanner] No se detectaron tiendas. Asegúrate de poner el Tag 'TiendaTag' o el nombre 'ShopBoard'.")
	end

	-- 5. Notificar al GameLoop
	workspace:SetAttribute("MapScanned", true)
	print("🚀 [AssetScanner] Escaneo finalizado.")
end

return AssetScanner

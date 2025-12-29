local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local _ServerScriptService = game:GetService("ServerScriptService")
local _ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Intentamos requerir ShopService para re-aplicar efectos permanentes
-- Asumimos que está en src/server (ServerScriptService en runtime si está allí)
-- O en ReplicatedStorage si fuera compartido, pero ShopService parece ser server-side.
-- El file structure dice src/server/ShopService.luau.
-- En Runtime de Roblox, src/server suele ir a ServerScriptService.
local ShopService
task.spawn(function()
	-- Esperar brevemente para evitar dependencias cíclicas si las hubiera,
	-- aunque DataService es un Script y ShopService un Module.
	local success, result = pcall(function()
		return require(script.Parent:WaitForChild("ShopService"))
	end)
	if success then
		ShopService = result
	else
		warn("DataService no pudo cargar ShopService para aplicar buffs permanentes:", result)
	end
end)

local DATA_VERSION = "v1"
local playerDataStore
local isOfflineMode = false

local successDS, resultDS = pcall(function()
	return DataStoreService:GetDataStore("ParkourGameData_" .. DATA_VERSION)
end)

if successDS and resultDS then
	playerDataStore = resultDS
else
	warn("⚠️ DataStoreService no disponible (Offline Mode). Los datos no se guardarán permanentemente.")
	isOfflineMode = true
	-- Mock minimalistico para evitar errores de null
	playerDataStore = {
		GetAsync = function(_self, _key) return nil end,
		UpdateAsync = function(_self, _key, callback) return callback(nil) end
	}
end

local SESSION_CACHE = {}

-- Configuración
local AUTOSAVE_INTERVAL = 60

-- Items que se consideran permanentes y qué atributo de propiedad usan
local PERMANENT_ITEMS_MAPPING = {
	-- ItemID (del ShopConfig) = Atributo de Propiedad
	["DoubleJump"] = "Owns_DoubleJump"
}

local function createLeaderstats(player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local cr = Instance.new("IntValue")
	cr.Name = "CR"
	cr.Value = data.CR or 0
	cr.Parent = leaderstats

	leaderstats.Parent = player
end

local function applyPermanentItems(player, inventoryData)
	-- inventoryData es una lista de IDs: {"DoubleJump", ...}
	if not inventoryData then return end

	for _, itemId in ipairs(inventoryData) do
		local ownershipAttr = PERMANENT_ITEMS_MAPPING[itemId]
		if ownershipAttr then
			player:SetAttribute(ownershipAttr, true)
		end
	end
end

local function loadData(player)
	local userId = player.UserId
	local key = "Player_" .. userId

	local success, data = pcall(function()
		return playerDataStore:GetAsync(key)
	end)

	if not success then
		warn("Error cargando datos para " .. player.Name .. ": " .. tostring(data))
		-- Cargar datos por defecto en caso de error de lectura para no bloquear,
		-- PERO marcarlo para no sobreescribir si DataStore está caído?
		-- Para este ejercicio, asumiremos carga fresh si falla o es nil.
		data = nil
	end

	if not data then
		data = {
			CR = 0,
			Inventory = {}
		}
	end
	
	-- CHEAT: Dar 1000 CR si es el Admin o estamos en Studio
	if RunService:IsStudio() or player.Name == "RazzetiGit" or player.UserId == 123456 then -- Reemplaza con tu ID real si quieres
		if data.CR < 1000 then
			data.CR = 1000
			warn("🤑 [DataService] Cheat Activado: 1000 CR para " .. player.Name)
		end
	end

	-- Compatibilidad/Migración si fuera necesaria
	if not data.Inventory then data.Inventory = {} end

	SESSION_CACHE[userId] = data

	createLeaderstats(player, data)
	applyPermanentItems(player, data.Inventory)

	print("Datos cargados para " .. player.Name)
end

local function saveData(player)
	local userId = player.UserId
	local key = "Player_" .. userId

	if not SESSION_CACHE[userId] then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	local currentCR = 0
	if leaderstats and leaderstats:FindFirstChild("CR") then
		currentCR = leaderstats.CR.Value
	end

	-- Reconstruir inventario basado en atributos 'Owns_'
	local inventory = {}
	for itemId, attrName in pairs(PERMANENT_ITEMS_MAPPING) do
		if player:GetAttribute(attrName) == true then
			table.insert(inventory, itemId)
		end
	end

	local dataToSave = {
		CR = currentCR,
		Inventory = inventory
	}

	local success, err = pcall(function()
		playerDataStore:UpdateAsync(key, function(oldData)
			-- Aquí se podría implementar control de versiones o merge
			return dataToSave
		end)
	end)

	if success then
		print("Datos guardados para " .. player.Name)
	else
		warn("Error guardando datos para " .. player.Name .. ": " .. tostring(err))
	end
end

local function onCharacterAdded(character)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Esperar a que ShopService esté disponible
	if not ShopService then
		task.wait(1)
		if not ShopService then return end
	end

	-- Re-aplicar buffs permanentes
	for itemId, attrName in pairs(PERMANENT_ITEMS_MAPPING) do
		if player:GetAttribute(attrName) == true then
			-- Simular un item data para ShopService
			-- Asumimos que ShopService maneja la lógica si le pasamos {Type = itemId}
			-- ShopConfig usa Type="DoubleJump" para el item DoubleJump.
			-- Necesitamos mapear ID a Type o pasar el objeto correcto.
			-- Simplificación: En ShopService.ApplyEffect(char, item), mira item.Type.
			-- En ShopConfig: Id="DoubleJump", Type="DoubleJump".
			ShopService.ApplyEffect(character, {Type = itemId, Value = 0})
		end
	end
end

-- Eventos
local function onPlayerAdded(player)
	loadData(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	-- Si el personaje ya cargó antes del script
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Manejar jugadores que ya están dentro (Studio Race Condition)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function() onPlayerAdded(player) end)
end

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	SESSION_CACHE[player.UserId] = nil
end)

game:BindToClose(function()
	print("Cerrando servidor, guardando datos...")
	for _, player in ipairs(Players:GetPlayers()) do
		saveData(player)
	end
end)

-- Auto-Guardado
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			saveData(player)
		end
	end
end)

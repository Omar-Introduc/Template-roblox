local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DATA_VERSION = "v1"
local playerDataStore
local leaderBoardStore -- OrderedDataStore for Global Ranking
local isOfflineMode = false

-- Remote Events / Functions
local Events = ReplicatedStorage:WaitForChild("Events")
local GetTopPlayers = Events:FindFirstChild("GetTopPlayers") or Instance.new("RemoteFunction")
GetTopPlayers.Name = "GetTopPlayers"
GetTopPlayers.Parent = Events

local ShopService
task.spawn(function()
	local success, result = pcall(function()
		return require(script.Parent:WaitForChild("ShopService"))
	end)
	if success then ShopService = result end
end)

local successDS, resultDS = pcall(function()
	return DataStoreService:GetDataStore("ParkourGameData_" .. DATA_VERSION)
end)

local successLB, resultLB = pcall(function()
	return DataStoreService:GetOrderedDataStore("GlobalCRLeaderboard_" .. DATA_VERSION)
end)

if successDS and resultDS then
	playerDataStore = resultDS
else
	warn("⚠️ DataStoreService no disponible (Offline Mode).")
	isOfflineMode = true
	playerDataStore = {
		GetAsync = function(_self, _key) return nil end,
		UpdateAsync = function(_self, _key, callback) return callback(nil) end
	}
end

if successLB and resultLB then
	leaderBoardStore = resultLB
end

local SESSION_CACHE = {}
local AUTOSAVE_INTERVAL = 60

local PERMANENT_ITEMS_MAPPING = {
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
	if not inventoryData then return end
	for _, itemId in ipairs(inventoryData) do
		local ownershipAttr = PERMANENT_ITEMS_MAPPING[itemId]
		if ownershipAttr then
			player:SetAttribute(ownershipAttr, true)
		end
	end
end

local function updateLeaderboard(player, score)
	if isOfflineMode or not leaderBoardStore then return end
	pcall(function()
		leaderBoardStore:SetAsync(tostring(player.UserId), score)
	end)
end

local function loadData(player)
	local userId = player.UserId
	local key = "Player_" .. userId

	local success, data = pcall(function()
		return playerDataStore:GetAsync(key)
	end)

	if not success or not data then
		data = { CR = 0, Inventory = {} }
	end
	
	if RunService:IsStudio() or player.Name == "RazzetiGit" then
		if data.CR < 1000 then data.CR = 1000 end
	end

	SESSION_CACHE[userId] = data
	createLeaderstats(player, data)
	applyPermanentItems(player, data.Inventory)
	updateLeaderboard(player, data.CR)
end

local function saveData(player)
	local userId = player.UserId
	local key = "Player_" .. userId

	if not SESSION_CACHE[userId] then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	local currentCR = (leaderstats and leaderstats:FindFirstChild("CR")) and leaderstats.CR.Value or 0

	updateLeaderboard(player, currentCR)

	local inventory = {}
	for itemId, attrName in pairs(PERMANENT_ITEMS_MAPPING) do
		if player:GetAttribute(attrName) == true then
			table.insert(inventory, itemId)
		end
	end

	local dataToSave = { CR = currentCR, Inventory = inventory }

	pcall(function()
		playerDataStore:UpdateAsync(key, function() return dataToSave end)
	end)
end

local function onCharacterAdded(character)
	local player = Players:GetPlayerFromCharacter(character)
	if not player or not ShopService then return end

	for itemId, attrName in pairs(PERMANENT_ITEMS_MAPPING) do
		if player:GetAttribute(attrName) == true then
			ShopService.ApplyEffect(character, {Type = itemId, Value = 0})
		end
	end
end

-- Remote Invocation
GetTopPlayers.OnServerInvoke = function(player)
	if isOfflineMode or not leaderBoardStore then return {} end
	local success, pages = pcall(function() return leaderBoardStore:GetSortedAsync(false, 10) end)
	if success then
		local top = {}
		local entries = pages:GetCurrentPage()
		for _, data in ipairs(entries) do
			local uid = tonumber(data.key)
			local name = "Player_" .. uid
			pcall(function() name = Players:GetNameFromUserIdAsync(uid) end)
			table.insert(top, {Name = name, Score = data.value})
		end
		return top
	end
	return {}
end

-- Events
Players.PlayerAdded:Connect(function(player)
	loadData(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then onCharacterAdded(player.Character) end
end)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(function() loadData(p) end)
end

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	SESSION_CACHE[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do saveData(player) end
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do saveData(player) end
	end
end)

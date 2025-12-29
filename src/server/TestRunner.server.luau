--!strict
local TestService = game:GetService("TestService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(Shared:WaitForChild("ShopConfig"))
local PlatformSpawner = require(Shared:WaitForChild("PlatformSpawner"))

-- Attempt to load Refactored Services
local success, ShopService = pcall(function() return require(script.Parent.ShopService) end)
if not success then warn("TestRunner: Could not require ShopService. Assuming Script not Module.") ShopService = nil end

local successGM, GameManager = pcall(function() return require(script.Parent.GameManager) end)
if not successGM then warn("TestRunner: Could not require GameManager. Assuming Script not Module.") GameManager = nil end


local function RunTests()
	print("\n🛡️ STARTING INTEGRATION & STRESS TESTS 🛡️\n")

	----------------------------------------------------------------
	-- 1. ASSET INTEGRITY (Static Analysis)
	----------------------------------------------------------------
	TestService:Message("🔎 1. Validating Assets...")

	local requiredFolders = {
		{Root = ReplicatedStorage, Name = "Shared"},
		{Root = ReplicatedStorage, Name = "Events"},
		{Root = ServerStorage, Name = "Prefabs"}
	}

	for _, req in ipairs(requiredFolders) do
		local folder = req.Root:FindFirstChild(req.Name)
		if folder then
			TestService:Check(true, "Folder Exists: " .. req.Name)
		else
			TestService:Check(false, "MISSING Folder: " .. req.Name)
		end
	end

	-- Validate ShopConfig
	local ids = {}
	for categoryName, category in pairs(ShopConfig.Categories) do
		for _, item in ipairs(category.Items) do
			if ids[item.Id] then
				TestService:Check(false, "❌ Duplicate Item ID found: " .. tostring(item.Id))
			else
				ids[item.Id] = true
			end

			if item.Price < 0 then
				TestService:Check(false, "❌ Negative Price for: " .. tostring(item.Id))
			end
		end
	end
	TestService:Check(true, "ShopConfig Integrity Verified")

	----------------------------------------------------------------
	-- 2. ECONOMY SIMULATION (ShopService)
	----------------------------------------------------------------
	TestService:Message("\n💰 2. Simulating Economy...")

	if ShopService then
		-- Create Mock Player
		local mockPlayer = Instance.new("Folder") -- Use Folder as Player Mock usually doesn't work for class checks unless proxied,
		-- actually ShopService expects 'player' to have leaderstats and Character.
		-- We need a construct that passes `player:FindFirstChild("leaderstats")`

		-- Better Mock: Create a dummy Folder that looks like a player for the function
		local mockPlyObj = {
			Name = "TestPlayer",
			UserId = 12345,
			Parent = Players
		}

		-- Create real objects for hierarchy checks
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"

		local points = Instance.new("IntValue")
		points.Name = "Points"
		points.Value = 0
		points.Parent = leaderstats

		-- Mock Character
		local char = Instance.new("Model")
		char.Name = "TestCharacter"
		local hum = Instance.new("Humanoid")
		hum.Parent = char

		-- Attach to mock
		local mockPlayerProxy = newproxy(true)
		local meta = getmetatable(mockPlayerProxy)
		meta.__index = function(_, key)
			if key == "Name" then return "TestPlayer" end
			if key == "UserId" then return 12345 end
			if key == "Character" then return char end
			if key == "FindFirstChild" then
				return function(_, childName)
					if childName == "leaderstats" then return leaderstats end
					return nil
				end
			end
			return nil
		end

		-- Test 2.1: Buy with 0 money
		local success, msg = ShopService.ProcessPurchase(mockPlayerProxy, "Speed1")
		if not success then
			TestService:Check(true, "✅ Purchase Blocked (Insufficient Funds)")
		else
			TestService:Check(false, "❌ Purchase Allowed with 0 funds!")
		end

		-- Test 2.2: Buy with money
		points.Value = 1000
		local success2, msg2 = ShopService.ProcessPurchase(mockPlayerProxy, "Speed1")
		if success2 then
			TestService:Check(true, "✅ Purchase Successful")
			TestService:Check(points.Value < 1000, "✅ Money Deducted")

			-- Verify Attribute
			if char:GetAttribute("Buff_WalkSpeed") then
				TestService:Check(true, "✅ Buff Attribute Applied")
			else
				TestService:Check(false, "❌ Buff Attribute Missing")
			end
		else
			TestService:Check(false, "❌ Purchase Failed with funds: " .. tostring(msg2))
		end

		char:Destroy()
		leaderstats:Destroy()
	else
		TestService:Warn("⚠️ ShopService not loaded as Module. Skipping Economy Tests.")
	end

	----------------------------------------------------------------
	-- 3. GAME LOOP (PlatformSpawner)
	----------------------------------------------------------------
	TestService:Message("\n🏗️ 3. Testing Platform Spawner...")

	local dummyFolder = Instance.new("Folder")
	dummyFolder.Name = "TestEstructuras"
	dummyFolder.Parent = workspace

	local dummyStart = Instance.new("Part")
	dummyStart.Name = "Plataforma_100"
	dummyStart.Position = Vector3.new(0,5,0)
	dummyStart.Parent = dummyFolder

	local newPlat = PlatformSpawner.SpawnNext(dummyStart, dummyFolder, 0)

	if newPlat and newPlat.Parent == dummyFolder then
		TestService:Check(true, "✅ Platform Generated in Workspace")
		TestService:Check(string.find(newPlat.Name, "Plataforma_101") ~= nil, "✅ Platform Naming Correct")
	else
		TestService:Check(false, "❌ Platform Generation Failed")
	end

	dummyFolder:Destroy()

	----------------------------------------------------------------
	-- 4. SECURITY & STRESS (GameManager)
	----------------------------------------------------------------
	TestService:Message("\n🛡️ 4. Security Stress Test (Spam)...")

	if GameManager and GameManager.ValidatePointRequest then
		local spamPlayer = {
			Name = "Spammer",
			UserId = 999,
			Character = Instance.new("Model")
		}
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Parent = spamPlayer.Character

		local platform = Instance.new("Part")
		platform.Name = "Plataforma_Testing"
		platform.Position = Vector3.zero
		root.Position = Vector3.zero -- Valid distance

		local successCount = 0
		local failCount = 0

		local start = os.clock()
		for i = 1, 20 do
			local valid, reason = GameManager.ValidatePointRequest(spamPlayer, platform)
			if valid then
				successCount += 1
			else
				failCount += 1
			end
		end
		local duration = os.clock() - start

		print("Spam Result: " .. successCount .. " Success, " .. failCount .. " Rejected in " .. duration .. "s")

		if successCount == 1 and failCount == 19 then
			TestService:Check(true, "✅ Rate Limit blocked spam correctly.")
		else
			TestService:Check(false, "❌ Security Breach! Allowed " .. successCount .. "/20 requests instantly.")
		end

		spamPlayer.Character:Destroy()
	else
		TestService:Warn("⚠️ GameManager not loaded or ValidatePointRequest not exposed. Skipping Stress Test.")
	end

	print("\n🏁 TESTS COMPLETED 🏁")
end

-- Run immediately
task.spawn(RunTests)

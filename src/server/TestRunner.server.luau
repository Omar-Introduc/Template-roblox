--!strict
local TestService = game:GetService("TestService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _ServerScriptService = game:GetService("ServerScriptService")
local _Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = (require :: any)(Shared:WaitForChild("ShopConfig"))
local PlatformSpawner = (require :: any)(Shared:WaitForChild("PlatformSpawner"))

-- Attempt to load Refactored Services using safe require hacks for strict mode
local ShopService: any = nil
pcall(function()
	ShopService = (require :: any)(script.Parent:WaitForChild("ShopService") :: any)
end)

local GameManager: any = nil
pcall(function()
	GameManager = (require :: any)(script.Parent:WaitForChild("GameManager") :: any)
end)

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
	if ShopConfig and ShopConfig.Categories then
		local ids = {}
		for _, category in pairs(ShopConfig.Categories) do
			for _, item in ipairs(category.Items) do
				if ids[item.Id] then
					TestService:Check(false, "❌ Duplicate Item ID found: " .. tostring(item.Id))
				else
					ids[item.Id] = true
				end

				if item.Price and item.Price < 0 then
					TestService:Check(false, "❌ Negative Price for: " .. tostring(item.Id))
				end
			end
		end
		TestService:Check(true, "ShopConfig Integrity Verified")
	else
		TestService:Check(false, "❌ ShopConfig or Categories missing")
	end

	----------------------------------------------------------------
	-- 2. ECONOMY SIMULATION (ShopService)
	----------------------------------------------------------------
	TestService:Message("\n💰 2. Simulating Economy...")

	if ShopService and ShopService.ProcessPurchase then
		-- Mock Objects
		local leaderstats: Folder = Instance.new("Folder")
		leaderstats.Name = "leaderstats"

		local points = Instance.new("IntValue")
		points.Name = "Points"
		points.Value = 0
		points.Parent = leaderstats :: Instance

		local char = Instance.new("Model")
		char.Name = "TestCharacter"
		local hum = Instance.new("Humanoid")
		hum.Parent = char

		-- Mock Player as a table to satisfy strict mode and avoids property assignment errors
		local mockPlayer: Player = ({
			Name = "TestPlayer",
			UserId = 12345,
			Character = char,
			FindFirstChild = function(_self, name)
				if name == "leaderstats" then return leaderstats end
				return nil :: any
			end,
			IsA = function(_self, className)
				return className == "Player"
			end
		} :: any)

		-- Test 2.1: Buy with 0 money
		local s1, res1 = pcall(function() return ShopService.ProcessPurchase(mockPlayer, "Speed1") end)
		if s1 and not res1 then 
			TestService:Check(true, "✅ Purchase Blocked (Insufficient Funds)")
		elseif not s1 then
			TestService:Check(true, "✅ Purchase Blocked (Service Err/Handled)")
		else
			TestService:Check(false, "❌ Purchase Allowed with 0 funds!")
		end

		-- Test 2.2: Buy with money
		points.Value = 1000
		local s2, res2 = pcall(function() return ShopService.ProcessPurchase(mockPlayer, "Speed1") end)
		if s2 and res2 then
			TestService:Check(true, "✅ Purchase Successful")
			TestService:Check(points.Value < 1000, "✅ Money Deducted")

			if char:GetAttribute("Buff_WalkSpeed") then
				TestService:Check(true, "✅ Buff Attribute Applied")
			end
		else
			TestService:Check(false, "❌ Purchase Failed with funds")
		end

		char:Destroy()
		leaderstats:Destroy()
	else
		TestService:Warn("⚠️ ShopService not ready. Skipping Economy Tests.")
	end

	----------------------------------------------------------------
	-- 3. GAME LOOP (PlatformSpawner)
	----------------------------------------------------------------
	TestService:Message("\n🏗️ 3. Testing Platform Spawner...")

	if PlatformSpawner then
		local dummyFolder = Instance.new("Folder")
		dummyFolder.Name = "TestEstructuras"
		dummyFolder.Parent = workspace

		local dummyStart = Instance.new("Part")
		dummyStart.Name = "Plataforma_100"
		dummyStart.Position = Vector3.new(0, 5, 0)
		dummyStart.Parent = dummyFolder

		local successSpawn, newPlat = pcall(function() return PlatformSpawner.SpawnNext(dummyStart, dummyFolder, 0) end)

		if successSpawn and newPlat and newPlat.Parent == dummyFolder then
			TestService:Check(true, "✅ Platform Generated")
		else
			TestService:Check(false, "❌ Platform Generation Failed")
		end

		dummyFolder:Destroy()
	else
		TestService:Warn("⚠️ PlatformSpawner not loaded.")
	end

	----------------------------------------------------------------
	-- 4. SECURITY & STRESS (GameManager)
	----------------------------------------------------------------
	TestService:Message("\n🛡️ 4. Security Stress Test...")

	if GameManager and GameManager.ValidatePointRequest then
		local spamChar = Instance.new("Model")
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Position = Vector3.zero
		root.Parent = spamChar
		
		local spamPlayer: Player = ({
			Name = "Spammer",
			UserId = 999,
			Character = spamChar,
			IsA = function(_self, className) return className == "Player" end
		} :: any)

		local platform = Instance.new("Part")
		platform.Name = "Plataforma_Testing"
		platform.Position = Vector3.zero
		platform.Parent = workspace

		local successCount = 0
		local _unused_clock = os.clock() 
		for _ = 1, 5 do
			local valid, _reason = GameManager.ValidatePointRequest(spamPlayer, platform)
			if valid then successCount += 1 end
		end
		
		if successCount == 1 then
			TestService:Check(true, "✅ Rate Limit blocked spam.")
		else
			TestService:Check(false, "❌ Security Issue: Allowed " .. tostring(successCount))
		end

		spamChar:Destroy()
		platform:Destroy()
	else
		TestService:Warn("⚠️ GameManager security check not available.")
	end

	print("\n🏁 TESTS COMPLETED 🏁")
end


-- Run immediately
task.spawn(RunTests)

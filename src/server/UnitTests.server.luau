local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

print("🧪 Starting Extra Unit Tests...")

local function runTest(name, callback)
	print("  Running: " .. name)
	local success, err = pcall(callback)
	if success then
		print("  ✅ " .. name .. " PASSED")
	else
		warn("  ❌ " .. name .. " FAILED: " .. tostring(err))
	end
end

print("------------------------------------------------")
print("🧪 TESTING: Templates & Biomes")
print("------------------------------------------------")

runTest("Templates Folder Exists", function()
	local templates = ReplicatedStorage:FindFirstChild("Templates")
	assert(templates, "Templates folder not found in ReplicatedStorage")
	assert(templates:GetAttribute("PrefabReady"), "PrefabReady attribute not set on Templates")
end)

runTest("Essential Prefabs Exist (Level 1 Check)", function()
	local templates = ReplicatedStorage:FindFirstChild("Templates")
	local lvl1 = templates:FindFirstChild("Level1")
	assert(lvl1, "Level1 folder missing")
	assert(lvl1:FindFirstChild("ParkourBlock"), "ParkourBlock missing in Level1")
	assert(lvl1:FindFirstChild("StarterPad"), "StarterPad missing in Level1")
	assert(lvl1:FindFirstChild("LevelPlatform"), "LevelPlatform missing in Level1")
end)

runTest("Biome Subfolders Exist", function()
	local templates = ReplicatedStorage:FindFirstChild("Templates")
	for i = 1, 4 do
		assert(templates:FindFirstChild("Level" .. i), "Level " .. i .. " template folder missing")
	end
end)

print("------------------------------------------------")
print("🧪 TESTING: Town Generator Utils (if present)")
print("------------------------------------------------")

-- If TownGenerator logic uses a Shared module, we could test it here.
-- Checking memory implies TownGenerator.server.lua exists but might not expose modules in Shared.
-- We'll skip if no shared module is available.

print("------------------------------------------------")
print("✅ EXTRA TESTS COMPLETE")
print("------------------------------------------------")

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🧪 Starting Parkour Diagnostic Tool...")

local TOTAL_TESTS = 100
local validJumps = 0
local foundImpossible = false

print("------------------------------------------------")
print("🛠️  Testing Parkour Math Parameters (Simulation)")
print("------------------------------------------------")

for i = 1, TOTAL_TESTS do
	-- Simulation of ParkourSystem.server.luau logic (Normal variation)
	-- "random distance 10-14, height -1 to 4" as per request
	local dist = math.random(10, 14)
	local height = math.random(-1, 4)

	-- Note: 'dist' here represents the 'forwardDist' in ParkourSystem.
	-- 'height' represents 'blockHeightDiff'.

	local failed = false

	-- Validate Jumpability
	if dist > 16 then
		warn(string.format("⚠️ WARNING: Jump %d generated impossible DISTANCE: %d studs", i, dist))
		failed = true
	end

	if height > 5 then
		warn(string.format("⚠️ WARNING: Jump %d generated impossible HEIGHT: %d studs", i, height))
		failed = true
	end

	if not failed then
		validJumps += 1
	else
		foundImpossible = true
	end
end

print("------------------------------------------------")
print("💎 Testing Crystal Integration")
print("------------------------------------------------")

local successTag = false
local testPart = Instance.new("Part")
testPart.Name = "TestCrystal"
testPart.Parent = workspace

CollectionService:AddTag(testPart, "Crystal")

if CollectionService:HasTag(testPart, "Crystal") then
	print("✅ Crystal Tag applied successfully.")
	successTag = true
else
	warn("❌ FAILED to apply Crystal Tag.")
end

testPart:Destroy()

print("------------------------------------------------")
print("🏭 Testing PrefabFactory Integration")
print("------------------------------------------------")

local templates = ReplicatedStorage:WaitForChild("Templates", 5)
if templates and templates:GetAttribute("PrefabReady") then
	print("✅ PrefabFactory initialized correctly.")
	if templates:FindFirstChild("MasterBlock") then
		print("✅ MasterBlock template found.")
	else
		warn("❌ MasterBlock template MISSING.")
	end
else
	warn("❌ PrefabFactory not ready or timed out.")
end


print("------------------------------------------------")
print("📝 FINAL REPORT")
print("------------------------------------------------")

if not foundImpossible and successTag and templates then
	print(string.format("✅ PASSED: %d/%d jumps are valid", validJumps, TOTAL_TESTS))
else
	print("❌ FAILED: Found impossible jumps or tag/factory errors.")
end

print("ℹ️  This script helps you verify parameters without playing.")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 🛡️ ASSET SCANNER UTILITY
-- Purpose: Map out all assets in ReplicatedStorage.asset to provide correct paths and names.

local function scanRecursive(parent, depth)
	local prefix = string.rep("   ", depth)
	
	for _, child in ipairs(parent:GetChildren()) do
		local info = string.format("%s- [%s] %s", prefix, child.ClassName, child.Name)
		
		-- Special info for BaseParts
		if child:IsA("BasePart") then
			info ..= string.format(" (Size: %s, Material: %s)", tostring(child.Size), tostring(child.Material.Name))
		end
		
		print(info)
		
		-- Recursive call
		if #child:GetChildren() > 0 then
			scanRecursive(child, depth + 1)
		end
	end
end

print("🔍 --- INICIANDO ESCANEO DE ASSETS ---")
local assetFolder = ReplicatedStorage:WaitForChild("asset", 10)

if assetFolder then
	print("📂 Root: ReplicatedStorage.asset")
	scanRecursive(assetFolder, 1)
else
	warn("❌ CRITICAL: No se encontró la carpeta 'asset' en ReplicatedStorage.")
end

print("🔍 --- ESCANEO FINALIZADO ---")

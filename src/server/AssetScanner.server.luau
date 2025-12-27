local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local MapManager = require(ReplicatedStorage.Shared.MapManager)

-- 🛡️ ASSET SCANNER (CORE)
-- Purpose: Scan workspace.estructuras and populate MapManager.
-- This script must run before GameLoop logic starts or GameLoop must wait for it.

local function scanMap()
    print("🔍 [AssetScanner] Starting map scan...")
    local estructuras = workspace:WaitForChild("estructuras", 10)

    if not estructuras then
        warn("❌ [AssetScanner] 'estructuras' folder not found in Workspace!")
        return
    end

    -- 1. Scan Lobby
    local lobby = estructuras:FindFirstChild("Lobby")
    if lobby then
        print("✅ [AssetScanner] Lobby found.")
        MapManager.SetLobby(lobby)
        CollectionService:AddTag(lobby, "Lobby")
    else
        warn("⚠️ [AssetScanner] Lobby not found in estructuras.")
    end

    -- 2. Scan ShopBoard
    local shopBoard = estructuras:FindFirstChild("ShopBoard")
    if shopBoard then
        print("✅ [AssetScanner] ShopBoard found.")
        MapManager.SetShopBoard(shopBoard)
        -- Ensure it's named correctly for Client to find if it relies on FindFirstChild
        -- The client currently looks for workspace.ShopBoard.
        -- We might need to keep it in estructuras but maybe Alias it or let client look in structures.
        -- For now, the prompt says "ShopUI... must find the static ShopBoard".
    else
        warn("⚠️ [AssetScanner] ShopBoard not found in estructuras.")
    end

    -- 3. Scan Platforms
    for _, child in ipairs(estructuras:GetChildren()) do
        if child.Name:match("^Plataforma_%d+") then
            -- Verify it's a part/model
            if child:IsA("BasePart") or child:IsA("Model") then
                print("✅ [AssetScanner] Platform found: " .. child.Name)
                MapManager.AddPlatform(child)

                -- Reset any runtime attributes just in case
                child:SetAttribute("Triggered", false)

                -- Ensure physics state (Static map = Anchored)
                if child:IsA("BasePart") then
                    child.Anchored = true
                elseif child:IsA("Model") then
                     if child.PrimaryPart then child.PrimaryPart.Anchored = true end
                end
            end
        end
    end

    print("🔍 [AssetScanner] Scan complete. " .. #MapManager.GetAllPlatforms() .. " platforms indexed.")

    -- Indicate scanning is done (could use an attribute on workspace or module)
    workspace:SetAttribute("MapScanned", true)
end

scanMap()

local ServerScriptService = game:GetService("ServerScriptService")

-- Since we refactored the services to be ModuleScripts (located in src/server which maps to ServerScriptService),
-- we need this loader to require them and start the game loop.

local GameManager = require(script.Parent.GameManager)
local ShopService = require(script.Parent.ShopService)

-- Initialize Services
print("🚀 ServiceLoader: Initializing Services...")

-- ShopService initializes its Events on require, no Start needed.
print("✅ ShopService Initialized")

-- GameManager needs explicit Start
if GameManager.Start then
    GameManager:Start()
    print("✅ GameManager Started")
else
    warn("⚠️ GameManager has no Start method!")
end

print("🏁 ServiceLoader: All Services Loaded.")

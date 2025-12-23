-- Performance Tracker (Client-side Juice & Stability Monitor)
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

print("📊 Performance Tracker: Active.")

local function getPerformanceReport()
    local player = game.Players.LocalPlayer
    local fps = math.floor(1 / RunService.RenderStepped:Wait())
    local ping = math.floor(player:GetNetworkPing() * 1000) -- Convert to ms
    local memory = math.floor(Stats:GetTotalMemoryUsageMb())
    
    return string.format("🚀 [PERF] FPS: %d | Ping: %dms | Mem: %dMB", fps, ping, memory)
end

-- Periodic Logging for Debugging
task.spawn(function()
    while true do
        print(getPerformanceReport())
        task.wait(30) -- Log every 30 seconds
    end
end)

--[[
    📊 PerformanceMonitor - Client Side

    Responsibilities:
    1. Collect FPS, Ping, Memory usage.
    2. Batch and send to server every 60s.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("ReportPerformance", 60)

if not remote then
    warn("PerformanceMonitor: Could not find ReportPerformance remote.")
    return
end

local function getFPS()
    return math.floor(workspace:GetRealPhysicsFPS())
end

local function getPing()
    return math.floor(player:GetNetworkPing() * 1000) -- ms
end

local function getMemory()
    return math.floor(Stats:GetTotalMemoryUsageMb())
end

while true do
    task.wait(60)

    local data = {
        FPS = getFPS(),
        Ping = getPing(),
        Memory = getMemory()
    }

    remote:FireServer(data)
end

--[[
    🩺 HealthCheck - Server Health Monitor & Performance Tracker

    Responsibilities:
    1. Monitor active block count and cleanup if > 200.
    2. Track player deaths for Heatmap.
    3. Handle Client Performance Reports.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Logger = require(ReplicatedStorage.Shared.Logger)

local MAX_BLOCKS = 200
local CHECK_INTERVAL = 30

-- Setup Remote for Performance
local perfRemote = Instance.new("RemoteEvent")
perfRemote.Name = "ReportPerformance"
perfRemote.Parent = ReplicatedStorage

perfRemote.OnServerEvent:Connect(function(player, data)
    Logger.reportPerformance(player, data)
end)

--------------------------------------------------------------------------------
-- 1. BLOCK CLEANUP MONITOR
--------------------------------------------------------------------------------
local function monitorBlocks()
    while true do
        task.wait(CHECK_INTERVAL)

        local pathBlocks = {}
        -- Find all blocks named "Path_*"
        for _, child in ipairs(Workspace:GetChildren()) do
            if child.Name:match("^Path_") then
                table.insert(pathBlocks, child)
            end
        end

        if #pathBlocks > MAX_BLOCKS then
            Logger.Warn(string.format("HealthCheck: Block count %d exceeds limit %d. Cleaning up...", #pathBlocks, MAX_BLOCKS))

            -- Simple cleanup: Remove oldest (assuming FIFO or random is okay for emergency)
            -- Ideally we remove blocks from players who left or are far away.
            -- For this implementation, we remove excess random blocks to restore health.
            local removeCount = #pathBlocks - MAX_BLOCKS
            for i = 1, removeCount do
                if pathBlocks[i] then
                    pathBlocks[i]:Destroy()
                end
            end
        else
            Logger.Info(string.format("HealthCheck: Block count stable (%d)", #pathBlocks))
        end
    end
end

--------------------------------------------------------------------------------
-- 2. DEATH HEATMAP TRACKER
--------------------------------------------------------------------------------
local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if humanoid then
            humanoid.Died:Connect(function()
                -- Track where they died
                -- We can check their Leaderstats Stage
                local stage = 0
                local ls = player:FindFirstChild("leaderstats")
                if ls and ls:FindFirstChild("Stage") then
                    stage = ls.Stage.Value
                end

                Logger.Info(string.format("HEATMAP: Player %s died at Level %d. Position: %s",
                    player.Name, stage, tostring(character.PrimaryPart and character.PrimaryPart.Position or "Unknown")))
            end)
        end
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
    onPlayerAdded(p)
end

task.spawn(monitorBlocks)

Logger.Info("HealthCheck Service Started.")

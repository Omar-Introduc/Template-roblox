--[[
    🤖 DebugConsole - Developer Tools

    Responsibilities:
    1. Listen for chat command /test_levels
    2. Spawn a dummy bot to simulate path traversal.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Logger = require(ReplicatedStorage.Shared.Logger)

-- Simplified Bot Simulation
local function runBotTest(player)
    Logger.Info("Starting Bot Test Simulation...")

    -- Create a dummy
    local dummy = Instance.new("Model")
    dummy.Name = "TestBot"
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 1)
    root.Transparency = 0.5
    root.Color = Color3.new(0, 1, 0)
    root.Anchored = true
    root.Parent = dummy
    local hum = Instance.new("Humanoid")
    hum.Parent = dummy
    dummy.Parent = Workspace

    -- Teleport to Lobby Start
    local lobby = Workspace:FindFirstChild("Lobby")
    if not lobby then
        Logger.Error("[TEST_FAILED] Lobby not found.")
        dummy:Destroy()
        return
    end

    root.CFrame = CFrame.new(lobby.Position + Vector3.new(0, 5, 0))
    Logger.Info("Bot spawned at Lobby.")

    -- Simulate attempting to hit the StarterPad
    local templates = ReplicatedStorage:FindFirstChild("Templates")
    local nextLevel = 1

    -- We need to find the StarterPad for Level 1 (it is in Lobby?)
    -- In ParkourSystem, createStarterPad(lobby, 0) spawns it.
    -- We look for "StarterPad_Level1" in Workspace

    task.spawn(function()
        -- Attempt to verify Level 1 to 4
        for i = 1, 4 do
             local padName = "StarterPad_Level" .. i
             local pad = Workspace:FindFirstChild(padName)
             if not pad then
                 Logger.Warn("[TEST_FAILED] Could not find " .. padName)
                 break
             end

             -- Teleport to pad
             root.CFrame = pad.CFrame * CFrame.new(0, 2, 0)
             Logger.Info("Bot reached " .. padName)
             task.wait(1)

             -- Simulate touching pad (ParkourSystem handles touch)
             -- Since ParkourSystem checks for Player, this simple dummy won't trigger it unless we mock a Player.
             -- LIMITATION: ParkourSystem.spawnBlock requires a Player instance.
             -- We cannot easily simulate a Player instance on Server.
             -- So we will stop here and Log.

             Logger.Info("Bot verified existence of " .. padName)

             -- To truly test jumping, we would need to mock the internal logic or use a real player.
             -- For this audit, verifying the pads exist is a good step.
        end

        task.wait(2)
        dummy:Destroy()
        Logger.Info("Bot Test Simulation Finished.")
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(msg)
        if msg == "/test_levels" then
            runBotTest(player)
        end
    end)
end)

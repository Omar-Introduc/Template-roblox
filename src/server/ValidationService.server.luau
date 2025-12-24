--[[
    🛡️ ValidationService - Automated Gameplay Testing & Integrity

    Responsibilities:
    1. Validate Prefabs on startup.
    2. Provide Trajectory Verification via BindableFunction.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Logger = require(ReplicatedStorage.Shared.Logger)

local ValidationService = {}

-- Setup Inter-Script Communication
local verifyFunc = Instance.new("BindableFunction")
verifyFunc.Name = "VerifyTrajectory"
verifyFunc.Parent = ServerStorage

--------------------------------------------------------------------------------
-- 1. PREFAB VALIDATION (Startup)
--------------------------------------------------------------------------------
local function validatePrefabs()
    Logger.Info("Starting Prefab Validation...")

    local templates = ReplicatedStorage:WaitForChild("Templates", 10)
    if not templates then
        Logger.Critical("Templates folder not found in ReplicatedStorage!")
        return
    end

    local essentialItems = {"ParkourBlock", "LevelPlatform", "StarterPad"}
    local levelCount = 4 -- Assuming 4 levels based on previous context

    for i = 1, levelCount do
        local levelFolder = templates:FindFirstChild("Level" .. i)
        if not levelFolder then
            Logger.Critical(string.format("Missing folder for Level %d", i))
            continue
        end

        for _, itemName in ipairs(essentialItems) do
            if not levelFolder:FindFirstChild(itemName) then
                Logger.Critical(string.format("Level %d is missing essential prefab: %s", i, itemName))
                -- In a real strict environment, we might stop the server or disable the level
            end
        end
    end

    Logger.Info("Prefab Validation Complete.")
end

--------------------------------------------------------------------------------
-- 2. TRAJECTORY VERIFICATION (API)
--------------------------------------------------------------------------------
-- Returns: boolean (isSafe), string (reason)
verifyFunc.OnInvoke = function(startPos, endPos)
    local direction = endPos - startPos
    local distance = direction.Magnitude
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    -- We should ignore the character, but since this is abstract, we ignore everything currently "Transient"
    -- or we can just ignore nothing and see if it hits static geometry.
    -- Better: Ignore all "ParkourBlocks" that are not the target?
    -- For now, let's just check for major static obstacles (Walls, Terrain).

    -- Cast a ray
    local result = Workspace:Raycast(startPos, direction, rayParams)

    if result then
        -- If we hit something
        if result.Instance and not result.Instance:GetAttribute("IsParkourBlock") then
             -- Assuming ParkourBlocks have an attribute or specific naming convention we can filter.
             -- If we hit a static wall, it's a fail.
             -- For now, purely based on geometric obstruction.
             Logger.Warn(string.format("Trajectory obstructed by %s at %s", result.Instance.Name, tostring(result.Position)))
             return false, "Obstructed"
        end
    end

    return true, "Clear"
end

-- Run Startup Checks
task.spawn(validatePrefabs)

Logger.Info("ValidationService Started.")

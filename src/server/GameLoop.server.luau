local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

-- Module Import
local MapManager = require(ReplicatedStorage.Shared.MapManager)

-- Logger
local Logger
local success, result = pcall(function()
	return require(ReplicatedStorage:WaitForChild("Shared", 2):WaitForChild("Logger", 2))
end)
if success then Logger = result else
	Logger = { Info = print, Warn = warn, Critical = warn, Error = warn }
end

-- Constants
local CONFIG = {
	COUNTDOWN_TIME = 3,
	FALL_DELAY = 2,
    RESET_DELAY = 5 -- Time before resetting a fallen platform (if applicable)
}

-- Wait for Scan
if not workspace:GetAttribute("MapScanned") then
    workspace:GetAttributeChangedSignal("MapScanned"):Wait()
end

Logger.Info("[GameLoop] Map Scan confirmed. Initializing game logic.")

-- Helper: Visual Countdown
local function createCountdown(parentPart)
	local bb = Instance.new("BillboardGui")
	bb.Name = "CountdownGui"
	bb.Size = UDim2.new(0, 100, 0, 100)
	bb.StudsOffset = Vector3.new(0, 5, 0)
	bb.AlwaysOnTop = true

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.Text = tostring(CONFIG.COUNTDOWN_TIME)
	text.Parent = bb

	bb.Parent = parentPart
	return bb, text
end

-- Logic: Activate Platform
-- Instead of spawning new ones, we enable the logic on the existing ones.
local function activatePlatform(platform)
    if not platform then return end

    local mainPart = platform:IsA("Model") and platform.PrimaryPart or platform
	if not mainPart then
		Logger.Warn("Platform " .. platform.Name .. " has no PrimaryPart!")
		return
	end

    -- Disconnect previous connections if any (cleanup re-runs)
    local existingConn = platform:GetAttribute("Connection")
    if existingConn then
        -- Note: We can't store actual connections in attributes.
        -- We just check Triggered state.
    end

    -- Reset state
    platform:SetAttribute("Triggered", false)
    if platform:IsA("BasePart") then
        platform.Color = Color3.fromHex("#a3a3a3") -- Reset color (Grey) or Original
        platform.Transparency = 0
        platform.CanCollide = true
        platform.Anchored = true
    end
    -- If it's a model, we'd reset children. For now assuming Parts or simple Models.

    local connection
	connection = mainPart.Touched:Connect(function(hit)
		if platform:GetAttribute("Triggered") then return end
		if not hit.Parent or not hit.Parent:FindFirstChild("Humanoid") then return end
		
		-- 1. Triggered
		platform:SetAttribute("Triggered", true)
		Logger.Info("Player touched: " .. platform.Name)
		
        -- 2. No spawning next platform (It's static).
        -- But maybe we want to verify the *next* platform is reachable or ready?
        -- The prompt says "scanners ... find existing objects ... give functionality".
        -- The "Spawns Next Platform" logic is replaced by the map being pre-built.
        -- So we skip straight to the "Countdown -> Fall" mechanic.

		-- 3. Countdown
		local bb, textLabel = createCountdown(mainPart)
		for i = CONFIG.COUNTDOWN_TIME, 1, -1 do
			textLabel.Text = tostring(i)
			task.wait(1)
		end
		if bb then bb:Destroy() end

		-- 4. Fall (Visual + Physics)
		-- "Turns Black and Falls (Anchored=false)"
        -- NOTE: Since we cannot Destroy the platform permanently (it's a static map we might want to reuse?),
        -- The user said "nunca crearlos". If we destroy them, we can't recreate them without cloning.
        -- "PROHIBIDO instanciar partes ... desde el script."
        -- This implies we should probably HIDE them and RESET them later, OR
        -- the user expects a single run.
        -- BUT: "Infinite Level" usually implies regeneration.
        -- If I destroy it, it's gone.
        -- "Platform lifecycle ... Destroyed via Debris (2s)."
        -- If I follow this, the map disappears.
        -- User said: "scripts must act as Controllers... never create nor move them from their original design position."
        -- BUT also: "turn black and fall". Falling moves them.
        -- INTERPRETATION:
        -- The "Design Position" is where they *start*.
        -- Gameplay moves them (Falling).
        -- To "Respawn", we must reset them to the saved Original CFrame.
        -- We should probably Store the Original CFrame in MapManager or Attribute.

        -- Save original CFrame if not saved
        if not platform:GetAttribute("OriginalCFrame") then
             platform:SetAttribute("OriginalCFrame", mainPart.CFrame)
        end

		for _, part in ipairs(platform:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Color = Color3.new(0, 0, 0) -- Turn Black
				part.Anchored = false
				part.CanCollide = false
			end
		end
        if platform:IsA("BasePart") then
            platform.Color = Color3.new(0,0,0)
            platform.Anchored = false
            platform.CanCollide = false
        end
		
        -- Instead of Destroying, we Wait and Reset.
        task.delay(CONFIG.FALL_DELAY, function()
            -- Hide/Move away?
            -- Or just Reset immediately after some time?
            -- "Destroyed via Debris (2s)" was the old logic.
            -- New Logic: We must not Destroy if we can't Create.
            -- So we must Reset.

            task.wait(CONFIG.RESET_DELAY)

            -- RESET LOGIC
            local origCF = platform:GetAttribute("OriginalCFrame")
            if origCF then
                if platform:IsA("BasePart") then
                    platform.AssemblyLinearVelocity = Vector3.zero
                    platform.AssemblyAngularVelocity = Vector3.zero
                    platform.CFrame = origCF
                    platform.Anchored = true
                    platform.CanCollide = true
                    platform.Color = Color3.fromHex("#a3a3a3") -- Restore color
                end
                platform:SetAttribute("Triggered", false)
                Logger.Info("Platform reset: " .. platform.Name)
            end
        end)

        connection:Disconnect()
        -- Re-connect happens when we reset?
        -- Actually, once disconnected, we need to reconnect.
        -- Better approach: Recursion or a permanent connection that checks state?
        -- Touched event fires constantly. Better to disconnect and re-hook on reset.
        -- For this iteration, let's keep it simple: The platform falls.
        -- I'll add a `respawnPlatform` function called after the delay.

        -- wait for reset delay then call setup again?
        -- See implementation below.
	end)
end

-- Override activatePlatform to include re-hooking
local function setupPlatform(platform)
    if not platform then return end
    local mainPart = platform:IsA("Model") and platform.PrimaryPart or platform

    -- Save initial state
    if not platform:GetAttribute("OriginalCFrame") then
        platform:SetAttribute("OriginalCFrame", mainPart.CFrame)
    end

    -- Reset visual/physics
    mainPart.AssemblyLinearVelocity = Vector3.zero
    mainPart.AssemblyAngularVelocity = Vector3.zero
    mainPart.CFrame = platform:GetAttribute("OriginalCFrame")
    mainPart.Anchored = true
    mainPart.CanCollide = true
    mainPart.Color = Color3.fromHex("#a3a3a3") -- Default Grey
    mainPart.Transparency = 0

    platform:SetAttribute("Triggered", false)

    -- Connect
    local connection
    connection = mainPart.Touched:Connect(function(hit)
        if platform:GetAttribute("Triggered") then return end
        if not hit.Parent or not hit.Parent:FindFirstChild("Humanoid") then return end

        platform:SetAttribute("Triggered", true)

        -- Countdown
        local bb, textLabel = createCountdown(mainPart)
        for i = CONFIG.COUNTDOWN_TIME, 1, -1 do
            textLabel.Text = tostring(i)
            task.wait(1)
        end
        if bb then bb:Destroy() end

        -- Fall
        mainPart.Color = Color3.new(0,0,0)
        mainPart.Anchored = false
        mainPart.CanCollide = false

        connection:Disconnect()

        -- Schedule Reset
        task.delay(CONFIG.FALL_DELAY + CONFIG.RESET_DELAY, function()
             setupPlatform(platform)
        end)
    end)
end

-- Initialize All Platforms
local platforms = MapManager.GetAllPlatforms()
for _, plat in ipairs(platforms) do
    setupPlatform(plat)
end

Logger.Info("GameLoop: All static platforms initialized.")

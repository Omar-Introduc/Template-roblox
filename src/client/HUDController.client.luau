-- src/client/HUDController.client.luau
--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UIComponents = require(game.ReplicatedStorage.Client.UIComponents) -- Adjusted path based on where UIComponents is (src/client maps to ReplicatedStorage.Client usually? Wait, src/client scripts run on client but modules need to be required from where they are replicated. src/client is usually PlayerScripts or StarterPlayerScripts, not ReplicatedStorage. But I created UIComponents in src/client. If the user's build system replicates src/client to PlayerScripts, I can require it relatively if it was a ModuleScript in the same folder, but HUDController is a LocalScript. LocalScripts can require ModuleScripts.
-- Wait, I created src/client/UIComponents.luau.
-- In Roblox, files in src/client usually go to StarterPlayerScripts.
-- So I should require it from there? Or maybe I should have put it in src/shared if I wanted it in ReplicatedStorage.
-- However, since both are in src/client, let's assume they are siblings in the runtime environment (PlayerScripts).
-- I will use `script.Parent:WaitForChild("UIComponents")` if possible, or assume standard Rojo structure where `src/client` -> `Players.LocalPlayer.PlayerScripts`.

local player = Players.LocalPlayer :: Player
local UITheme = require(ReplicatedStorage.Shared.UITheme)

-- We need to locate UIComponents. Since it's in src/client, it should be in PlayerScripts alongside this script.
local UIComponentsModule = script.Parent:WaitForChild("UIComponents")
local UIComponents = require(UIComponentsModule)

if not player then
	return
end

-- Wait for leaderstats
local leaderstats = player:WaitForChild("leaderstats", 10) :: Folder?
if not leaderstats then
	warn("HUDController: 'leaderstats' not found.")
	return
end

local crStatInstance = (leaderstats :: Folder):WaitForChild("CR", 10)
if not crStatInstance or not crStatInstance:IsA("IntValue") then
	warn("HUDController: 'CR' stat not found.")
	return
end
local crStat = crStatInstance :: IntValue

-- Create Main HUD GUI
local gui = Instance.new("ScreenGui")
gui.Name = "GameHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- 1. Money Display (Top Left or Bottom Left)
--------------------------------------------------------------------------------
local moneyContainer = UIComponents.CreateContainer({
	Name = "MoneyContainer",
	Size = UDim2.new(0, 180, 0, 45),
	Position = UDim2.new(0, 20, 1, -65),
	BackgroundColor3 = UITheme.Colors.BackgroundPanel,
	Transparency = 0.2,
	Parent = gui
})

-- Icon (Simple text circle for now, or Image if available)
local moneyIcon = Instance.new("Frame")
moneyIcon.Size = UDim2.new(0, 30, 0, 30)
moneyIcon.Position = UDim2.new(0, 8, 0.5, -15)
moneyIcon.BackgroundColor3 = UITheme.Colors.AccentOrange
moneyIcon.BorderSizePixel = 0
local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1,0)
iconCorner.Parent = moneyIcon
moneyIcon.Parent = moneyContainer

local iconLabel = UIComponents.CreateLabel({
	Text = "$",
	Size = UDim2.new(1,0,1,0),
	TextColor3 = Color3.new(0,0,0),
	Font = UITheme.Fonts.Header,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = moneyIcon
})

-- Value Text
local moneyLabel = UIComponents.CreateLabel({
	Name = "ValueLabel",
	Text = tostring(crStat.Value),
	Size = UDim2.new(1, -50, 1, 0),
	Position = UDim2.new(0, 45, 0, 0),
	TextColor3 = UITheme.Colors.TextHighlight,
	Font = UITheme.Fonts.Header,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = moneyContainer
})

local function updateMoney()
	moneyLabel.Text = tostring(crStat.Value)
	-- Pulse animation
	local tween = TweenService:Create(moneyLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
		TextColor3 = Color3.new(1,1,1)
	})
	tween:Play()
end
crStat.Changed:Connect(updateMoney)


--------------------------------------------------------------------------------
-- 2. Buffs Display (Vertical Stack, Middle Left or Right)
--------------------------------------------------------------------------------
local buffsContainer = Instance.new("Frame")
buffsContainer.Name = "BuffsContainer"
buffsContainer.Size = UDim2.new(0, 220, 0, 300)
buffsContainer.Position = UDim2.new(0, 20, 0.5, -150) -- Middle Left
buffsContainer.BackgroundTransparency = 1
buffsContainer.Parent = gui

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = buffsContainer

local activeBuffFrames = {} -- [AttributeName] = Frame

local buffConfig = {
	["Buff_Fly_End"] = { Name = "FLY", Color = UITheme.Colors.AccentCyan },
	["Buff_God_End"] = { Name = "GOD MODE", Color = UITheme.Colors.AccentHighlight }, -- Note: using text highlight gold?
	["Buff_Multiplier_End"] = { Name = "2X POINTS", Color = UITheme.Colors.AccentOrange },
	["Buff_Gravity_End"] = { Name = "LOW GRAVITY", Color = UITheme.Colors.AccentPurple },
	["Buff_DoubleJump"] = { Name = "DOUBLE JUMP", Color = UITheme.Colors.AccentGreen },
	["PointMultiplier"] = { Name = "MULTIPLIER", Color = UITheme.Colors.AccentOrange },
}
-- Fix God Mode Color reference if missing
if not buffConfig["Buff_God_End"].Color then buffConfig["Buff_God_End"].Color = UITheme.Colors.TextHighlight end


local function formatTime(seconds: number): string
	local m = math.floor(seconds / 60)
	local s = math.floor(seconds % 60)
	return string.format("%d:%02d", m, s)
end

RunService.Heartbeat:Connect(function()
	local character = player.Character
	if not character then return end

	local now = os.time()
	local attributes = character:GetAttributes()
	local currentBuffs = {}

	for name, val in pairs(attributes) do
		local isBuff = string.sub(name, 1, 5) == "Buff_"
		local isMultiplier = name == "PointMultiplier"
		local isShield = name == "HasShield"
		local isDoubleJump = name == "Owns_DoubleJump"
		
		if isBuff or isMultiplier or isShield or isDoubleJump then
			local timeLeft = 0
			local isTimer = false
			local displayValue = ""
			local maxTime = 60 -- Default fallback for progress bar

			if typeof(val) == "number" then
				if string.sub(name, -4) == "_End" then
					if val > now then
						timeLeft = val - now
						isTimer = true
						-- Try to guess max time? Hard without config.
						-- We will just show text mostly.
					else
						continue
					end
				else
					displayValue = "x" .. tostring(val)
				end
			elseif typeof(val) == "boolean" and val == true then
				displayValue = "ON"
			else
				continue
			end

			currentBuffs[name] = true

			-- Create or Update UI
			local frame = activeBuffFrames[name]
			local config = buffConfig[name]
			local displayName = config and config.Name or name:gsub("Buff_", ""):gsub("_End", "")
			local displayColor = config and config.Color or UITheme.Colors.AccentCyan

			if not frame then
				-- Create new Buff Frame
				frame = UIComponents.CreateContainer({
					Name = name,
					Size = UDim2.new(1, 0, 0, 36),
					BackgroundColor3 = Color3.new(0,0,0),
					Transparency = 0.6,
					Parent = buffsContainer
				})
				
				-- Icon/Color Strip
				local strip = Instance.new("Frame")
				strip.Size = UDim2.new(0, 4, 1, -8)
				strip.Position = UDim2.new(0, 6, 0, 4)
				strip.BackgroundColor3 = displayColor
				strip.BorderSizePixel = 0
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(1,0)
				corner.Parent = strip
				strip.Parent = frame

				-- Text
				local label = UIComponents.CreateLabel({
					Name = "Text",
					Text = displayName,
					Size = UDim2.new(1, -20, 1, 0),
					Position = UDim2.new(0, 15, 0, 0),
					TextColor3 = UITheme.Colors.TextPrimary,
					Font = UITheme.Fonts.Bold,
					TextSize = 14,
					Parent = frame
				})

				activeBuffFrames[name] = frame
			end

			-- Update Text
			local label = frame:FindFirstChild("Text") :: TextLabel
			if isTimer then
				label.Text = displayName .. "  " .. formatTime(timeLeft)
				label.TextColor3 = UITheme.Colors.TextPrimary
			else
				label.Text = displayName .. "  " .. displayValue
				label.TextColor3 = displayColor
			end
		end
	end

	-- Cleanup
	for name, frame in pairs(activeBuffFrames) do
		if not currentBuffs[name] then
			frame:Destroy()
			activeBuffFrames[name] = nil
		end
	end
end)

print("HUDController: Enhanced UI Loaded.")

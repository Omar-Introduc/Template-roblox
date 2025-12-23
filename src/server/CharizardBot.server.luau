-- CharizardBot.server.luau (Optimized Server-Side)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local _LOBBY_CENTER = Vector3.new(0, 0, 0)
local _PATROL_RADIUS = 30
local _FLOAT_HEIGHT = 12
local _ROTATION_SPEED = 0.5 -- Rads per second

-- Light Server Logic: Only handles Position & State
-- Static Position (Guardian of the Lobby)
local STATIC_POS = Vector3.new(0, 8, -15)

local function setStaticPosition(model)
	-- Face center
	local lookAt = Vector3.new(0, 8, 0)
	model:PivotTo(CFrame.lookAt(STATIC_POS, lookAt))
end

local function startRoarCycle(model)
	task.spawn(function()
		while model.Parent do
			task.wait(5) -- Every 5 seconds as requested
			
			-- Signal Clients to play animation
			model:SetAttribute("IsRoaring", true)
			
			-- Duration of roar
			task.wait(2.5)
			
			-- Reset signal
			model:SetAttribute("IsRoaring", false)
		end
	end)
end

local function spawnBot()
	local templates = ReplicatedStorage:WaitForChild("Templates")
	local charizard = templates:WaitForChild("Charivoxel"):Clone()
	charizard.Parent = Workspace
	
	-- No animation setup here (handled by client)
	setStaticPosition(charizard)
	startRoarCycle(charizard)
	print("🔥 CharizardBot: Server patrol started. Animation delegated to clients.")
end

-- Wait for Factory & Lobby
local templates = ReplicatedStorage:WaitForChild("Templates")
while not templates:GetAttribute("CharizardReady") or not templates:GetAttribute("PrefabReady") do 
	task.wait(0.1) 
end

spawnBot()

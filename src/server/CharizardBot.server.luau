-- CharizardBot.server.luau (Optimized Server-Side)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LOBBY_CENTER = Vector3.new(0, 0, 0)
local PATROL_RADIUS = 30
local FLOAT_HEIGHT = 12
local _ROTATION_SPEED = 0.5 -- Rads per second

-- Light Server Logic: Only handles Position & State
local function startPatrol(model)
	task.spawn(function()
		local angle = 0
		while model.Parent do
			angle += 0.01
			
			local x = math.cos(angle) * PATROL_RADIUS
			local z = math.sin(angle) * PATROL_RADIUS
			local y = FLOAT_HEIGHT + math.sin(angle * 3) * 2 -- Sine wave Y
			
			local targetPos = LOBBY_CENTER + Vector3.new(x, y, z)
			local lookAtPos = LOBBY_CENTER + Vector3.new(math.cos(angle + 0.1) * PATROL_RADIUS, y, math.sin(angle + 0.1) * PATROL_RADIUS)
			
			-- Server only updates Global Position (Replicated to Clients)
			model:PivotTo(CFrame.lookAt(targetPos, lookAtPos))
			
			task.wait()
		end
	end)
end

local function startRoarCycle(model)
	task.spawn(function()
		while model.Parent do
			task.wait(math.random(15, 25)) -- Intervals
			
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
	startPatrol(charizard)
	startRoarCycle(charizard)
	print("🔥 CharizardBot: Server patrol started. Animation delegated to clients.")
end

-- Wait for Factory & Lobby
local templates = ReplicatedStorage:WaitForChild("Templates")
while not templates:GetAttribute("CharizardReady") or not templates:GetAttribute("PrefabReady") do 
	task.wait(0.1) 
end

spawnBot()

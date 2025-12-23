local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local _Debris = game:GetService("Debris")
local _CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Wait for Factory
print("🏃 ParkourSystem: Waiting for Templates in ReplicatedStorage...")
local Templates = ReplicatedStorage:WaitForChild("Templates", 15)
if not Templates then
	error("🛑 ParkourSystem: TIMEOUT waiting for Templates folder!")
end

print("🏃 ParkourSystem: Waiting for FactoryReady signal...")
local ready = Templates:WaitForChild("FactoryReady", 15)
if not ready then
	error("🛑 ParkourSystem: TIMEOUT waiting for FactoryReady signal!")
end
print("🏃 ParkourSystem: Factory is ready. Starting level generation...")

-- 1. Configuration: Path & Levels (Optimized Spiral)
local LEVEL_CONFIGS = {
	{ Position = Vector3.new(150, 35, 0), Name = "Level1" },
	{ Position = Vector3.new(0, 70, 150), Name = "Level2" },
	{ Position = Vector3.new(-150, 105, 0), Name = "Level3" },
	{ Position = Vector3.new(0, 140, -150), Name = "Level4" },
}

local BIOME_CONFIG = {
	[1] = {
		Name = "Level1",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(0, 255, 100),
		ParticleColor = ColorSequence.new(Color3.fromRGB(50, 200, 50)),
		Texture = "rbxassetid://6736340536"
	},
	[2] = {
		Name = "Level2",
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(0, 150, 255),
		ParticleColor = ColorSequence.new(Color3.fromRGB(150, 220, 255)),
		Texture = "rbxassetid://243004475"
	},
	[3] = {
		Name = "Level3",
		Material = Enum.Material.CrackedLava,
		Color = Color3.fromRGB(255, 80, 0),
		ParticleColor = ColorSequence.new(Color3.fromRGB(255, 100, 0), Color3.fromRGB(255, 200, 0)),
		Texture = "rbxassetid://242291244"
	},
	[4] = {
		Name = "Level4",
		Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(180, 0, 255),
		ParticleColor = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 0, 255)),
		Texture = "rbxassetid://585426142"
	}
}

local LOBBY_RADIUS = 45 

-- 2. Dynamic Difficulty System
local DIFFICULTY_SETTINGS = {
	[1] = { MinDist = 12, MaxDist = 14, Variance = 3.5, Time = 5, MobileChance = 0 },
	[2] = { MinDist = 14, MaxDist = 16, Variance = 5.0, Time = 4.5, MobileChance = 0.2 }, -- 20% móviles
	[3] = { MinDist = 16, MaxDist = 18, Variance = 6.5, Time = 4, MobileChance = 0.4 },   -- 40% móviles
	[4] = { MinDist = 17, MaxDist = 20, Variance = 8.0, Time = 3.5, MobileChance = 0.6 },  -- 60% móviles y muy lejos
}

local ATMOSPHERE_COLORS = {
	[1] = Color3.fromRGB(150, 255, 180),
	[2] = Color3.fromRGB(130, 180, 255),
	[3] = Color3.fromRGB(255, 100, 50),
	[4] = Color3.fromRGB(150, 50, 255),
}

-- State
local playerPaths = {} -- player -> { LastBlock = Part, AllBlocks = {Part, ...} }
local playerProgress = {} -- player -> Highest Level Index Reached
local playerStreaks = {} -- player -> Current consecutive jumps count
local levelParts = {} -- levelIndex -> Part

-- Forward declaration to allow mutual recursion if needed
local spawnNextBlock
local setupBlockEvents
local cleanupPlayerPath
local startPath

--------------------------------------------------------------------------------
-- VISUALS: Animations & Countdown
--------------------------------------------------------------------------------

local function applyBiome(part, biome)
	part.Color = biome.Color
	part.Material = biome.Material
	
	local selectionBox = part:FindFirstChild("NeonBorder")
	if selectionBox then selectionBox.Color3 = biome.Color end
	
	local highlight = part:FindFirstChild("BlockHighlight")
	if highlight then highlight.FillColor = biome.Color end

	-- Add Particles
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "BiomeEffect"
	emitter.Color = biome.ParticleColor
	emitter.Texture = biome.Texture
	emitter.Size = NumberSequence.new(0.5, 0)
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Rate = 0 -- Triggered via Emit()
	emitter.Speed = NumberRange.new(2, 5)
	emitter.Parent = part
end

local function makePlatformMove(block, levelIndex)
	local distance = 5 + levelIndex -- Más rango de movimiento en niveles altos
	local speed = 2 -- Segundos por ciclo
	local originalPos = block.Position
	-- Dirección aleatoria horizontal
	local direction = Vector3.new(math.random(-100, 100)/100, 0, math.random(-100, 100)/100).Unit
	
	task.spawn(function()
		while block and block.Parent do
			local offset = math.sin(tick() * (math.pi / speed)) * distance
			block.Position = originalPos + (direction * offset)
			task.wait()
		end
	end)
end

local function applyRewards(player, stage)
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Level 2: WalkSpeed
	if stage >= 2 then
		humanoid.WalkSpeed = 20
	end

	-- Level 4: Particles
	if stage >= 4 then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp and not hrp:FindFirstChild("EliteEffect") then
			local particles = Instance.new("ParticleEmitter")
			particles.Name = "EliteEffect"
			particles.Texture = "rbxassetid://585426142" -- Stars
			particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)) -- Gold
			particles.Size = NumberSequence.new(0.5, 0)
			particles.Lifetime = NumberRange.new(0.5, 1)
			particles.Rate = 20
			particles.Speed = NumberRange.new(2, 5)
			particles.Parent = hrp
		end
	end

	-- Level-based Trail
	if stage > 0 then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp:ClearAllChildren() -- Reset effects on spawn/stage change (be careful with other items)
			-- Re-apply level 4 if needed
			if stage >= 4 then
				-- Redo particles if we cleared them
			end
			
			local attachment0 = Instance.new("Attachment", hrp)
			attachment0.Position = Vector3.new(0, 1, 0)
			local attachment1 = Instance.new("Attachment", hrp)
			attachment1.Position = Vector3.new(0, -1, 0)
			
			local trail = Instance.new("Trail")
			trail.Attachment0 = attachment0
			trail.Attachment1 = attachment1
			trail.Lifetime = 0.5
			trail.Transparency = NumberSequence.new(0.2, 1)
			
			local _config = LEVEL_CONFIGS[stage]
			local color = Color3.fromRGB(255,255,255)
			if stage == 1 then color = Color3.fromRGB(0, 255, 100)
			elseif stage == 2 then color = Color3.fromRGB(0, 150, 255)
			elseif stage == 3 then color = Color3.fromRGB(255, 80, 0)
			elseif stage == 4 then color = Color3.fromRGB(180, 0, 255) end
			
			trail.Color = ColorSequence.new(color)
			trail.Parent = hrp
		end
	end
end

-- Appearance handled on client via ParkourClient

local function createCountdown(block, duration)
	block:SetAttribute("RemainingTime", duration)

	task.spawn(function()
		while true do
			local remaining = block:GetAttribute("RemainingTime") or 0
			if remaining <= 0 or not block.Parent then break end
			task.wait(0.1)
			block:SetAttribute("RemainingTime", remaining - 0.1)
		end

		if block and block.Parent then
			local disintegrateTween = TweenService:Create(block, TweenInfo.new(0.2), {
				Size = Vector3.new(0, 0, 0), Transparency = 1
			})
			disintegrateTween:Play()
			disintegrateTween.Completed:Connect(function() block:Destroy() end)
		end
	end)
end

--------------------------------------------------------------------------------
-- CORE LOGIC
--------------------------------------------------------------------------------

spawnNextBlock = function(player, levelIndex, originOverride)
	local diff = DIFFICULTY_SETTINGS[levelIndex]
	local biome = BIOME_CONFIG[levelIndex]
	local folder = Templates
	
	local path = playerPaths[player]
	local lastBlock = originOverride or path.LastBlock
	if not lastBlock then 
		warn("🏃 ParkourSystem: spawnNextBlock failed - no origin for player " .. player.Name)
		return nil 
	end
	
	local lastPos = lastBlock.Position
	
	local targetLevel = LEVEL_CONFIGS[levelIndex]
	local targetPos = targetLevel.Position
	
	-- 1. Calculate the Direct Vector towards target
	local vectorToTarget = (targetPos - lastPos)
	local distToTarget = vectorToTarget.Magnitude
	local dirToTarget = vectorToTarget.Unit
	
	-- 2. Determine Jump Distance with Overshoot Protection
	local jumpDist = math.random(diff.MinDist * 10, diff.MaxDist * 10) / 10
	
	-- If very close, just snap slightly before the platform to ensure a good final jump
	if distToTarget < jumpDist + 10 then
		jumpDist = math.max(diff.MinDist, distToTarget - 8)
	end
	
	-- 3. Horizontal Direction with Variance
	local horizontalDir = Vector3.new(dirToTarget.X, 0, dirToTarget.Z).Unit
	local angle = (math.random() - 0.5) * math.rad(diff.Variance * 12)
	local rotatedDir = CFrame.Angles(0, angle, 0) * horizontalDir
	
	-- FORZAR DISTANCIA MÁXIMA en Niveles Altos si no es móvil
	local willMove = math.random() < (diff.MobileChance or 0)
	if levelIndex >= 3 and not willMove then
		jumpDist = math.random(diff.MaxDist - 1, diff.MaxDist)
	end

	-- 4. Calculate Vertical Step
	local heightStep = (targetPos.Y - lastPos.Y) * (jumpDist / distToTarget)
	
	local finalPos = lastPos + (rotatedDir * jumpDist) + Vector3.new(0, heightStep, 0)
	
	-- 5. Safety: Boundary Check
	if (finalPos - targetPos).Magnitude < 10 then
		finalPos = lastPos + (dirToTarget * (distToTarget - 12))
	end
	
	if (finalPos * Vector3.new(1, 0, 1)).Magnitude < LOBBY_RADIUS then
		local pushDir = (finalPos * Vector3.new(1, 0, 1)).Unit
		local horizontalOffset = pushDir * LOBBY_RADIUS
		finalPos = Vector3.new(horizontalOffset.X, finalPos.Y, horizontalOffset.Z)
	end
	
	-- 6. Clone & Setup Block
	local block = folder.MasterBlock:Clone()
	block.Name = "Path_" .. player.Name
	block.Position = finalPos
	block.Parent = Workspace
	
	if willMove then
		block.Color = Color3.fromRGB(255, 255, 0) -- Amarillo = Peligro/Móvil
		makePlatformMove(block, levelIndex)
	end

	-- Tip Adicional: Trampa Nivel 4 (Se rompe más rápido)
	if levelIndex == 4 and math.random() < 0.5 then
		block:SetAttribute("MaxTouches", 1)
		block.Transparency = 0.5 -- Visual cue that it's fragile
	end
	
	-- Apply Biome Skin
	applyBiome(block, biome)
	
	-- 30% Chance to Spawn a Gem
	if math.random() <= 0.3 then
		local gem = folder.MasterGem:Clone()
		gem.Position = finalPos + Vector3.new(0, 4, 0)
		gem.Parent = Workspace
		
		applyBiome(gem, biome)
		
		task.spawn(function()
			while gem.Parent do
				gem.CFrame = gem.CFrame * CFrame.Angles(0, math.rad(5), 0)
				task.wait()
			end
		end)

		local collected = false
		gem.Touched:Connect(function(hit)
			if collected then return end
			local p = Players:GetPlayerFromCharacter(hit.Parent)
			if p and p == player then
				collected = true
				
				-- Multiplier Logic: 1.5x after 10 jumps, 2x after 20 jumps
				local streak = playerStreaks[player] or 0
				local multiplier = 1
				if streak >= 20 then multiplier = 2
				elseif streak >= 10 then multiplier = 1.5 end
				
				local ls = p:FindFirstChild("leaderstats")
				if ls then
					local gVal = ls:FindFirstChild("Gems")
					if gVal then gVal.Value += math.floor(1 * multiplier) end
				end
				
				-- Feedback Musical y Visual
				local sound = gem:FindFirstChild("GemSound")
				if sound then sound:Play() end
				
				-- Popup de texto
				local part = Instance.new("Part")
				part.Size = Vector3.new(1, 1, 1)
				part.Position = gem.Position
				part.Anchored = true
				part.CanCollide = false
				part.Transparency = 1
				part.Parent = Workspace
				
				local billGui = Instance.new("BillboardGui")
				billGui.Size = UDim2.fromScale(4, 1.5)
				billGui.Adornee = part
				billGui.AlwaysOnTop = true
				billGui.Parent = part
				
				local label = Instance.new("TextLabel")
				label.Size = UDim2.fromScale(1, 1)
				label.BackgroundTransparency = 1
				label.Text = "+1 Gems!"
				label.TextColor3 = Color3.new(1, 0.8, 0)
				label.Font = Enum.Font.GothamBold
				label.TextScaled = true
				label.Parent = billGui
				
				TweenService:Create(part, TweenInfo.new(1), {Position = part.Position + Vector3.new(0, 4, 0)}):Play()
				game:GetService("Debris"):AddItem(part, 1)

				local currentTime = block:GetAttribute("RemainingTime") or 0
				block:SetAttribute("RemainingTime", currentTime + 0.5)
				TweenService:Create(gem, TweenInfo.new(0.2), {Size = Vector3.new(0,0,0), Transparency = 1}):Play()
				task.wait(0.2)
				gem:Destroy()
			end
		end)
		game:GetService("Debris"):AddItem(gem, diff.Time + 2)
	end

	-- Animations handled on client
	createCountdown(block, diff.Time)

	path.LastBlock = block
	table.insert(path.AllBlocks, block)
	
	setupBlockEvents(player, block)

	return block
end

setupBlockEvents = function(player, block)
	local triggered = false
	block.Touched:Connect(function(hit)
		if triggered then return end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			local pathData = playerPaths[player]
			if pathData and pathData.LastBlock == block then
				triggered = true
				
				-- JUICE: Sound & Step-down animation
				local sound = block:FindFirstChild("JumpSound")
				if sound then sound:Play() end
				
				local originalPos = block.Position
				local stepInfo = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				TweenService:Create(block, stepInfo, {Position = originalPos - Vector3.new(0, 0.3, 0)}):Play()
				
				-- Set an attribute to let the client know it was stepped on (for UI pulse)
				block:SetAttribute("Stepped", true)

				local targetLevel = pathData.TargetLevel or 1
				local nextBlock = spawnNextBlock(player, targetLevel)
				if nextBlock then
					pathData.LastBlock = nextBlock
				else
					pathData.LastBlock = nil
				end
			end
		end
	end)
end

cleanupPlayerPath = function(player)
	if playerPaths[player] then
		for _, b in pairs(playerPaths[player].AllBlocks) do
			if b and b.Parent then
				-- Increment Streak
				local streak = (playerStreaks[player] or 0) + 1
				playerStreaks[player] = streak
				player:SetAttribute("Streak", streak)
				
				-- Feedback visual del streak (opcional)
				if (streak) % 10 == 0 then
					print("🔥 [STREAK] " .. player.Name .. " is on fire! Multiplier active.")
				end
				
				b:Destroy() 
			end
		end
	end
	playerPaths[player] = nil
end

startPath = function(player, startPad, targetLevel)
	cleanupPlayerPath(player)

	playerPaths[player] = {
		LastBlock = nil,
		AllBlocks = {},
		TargetLevel = targetLevel
	}

	local firstBlock = spawnNextBlock(player, targetLevel, startPad)

	if firstBlock then
		playerPaths[player].LastBlock = firstBlock
	end
end

--------------------------------------------------------------------------------
-- LEVEL & PAD SETUP
--------------------------------------------------------------------------------

local function createStarterPads()
	-- Wait for the Lobby to be created by lobby.server.luau
	local lobbyPart = Workspace:WaitForChild("Lobby", 10)
	if not lobbyPart then
		warn("⚠️ Lobby not found! Make sure lobby.server.luau is running.")
		return
	end

	local function makePad(sourcePart, levelIndexForUnlock)
		local targetLevelIndex = levelIndexForUnlock + 1
		local biome = BIOME_CONFIG[targetLevelIndex]
		local targetPos = LEVEL_CONFIGS[targetLevelIndex].Position
		
		local pad = Templates.MasterPad:Clone()
		pad.Name = "StarterPad_Level" .. targetLevelIndex
		
		applyBiome(pad, biome)

		local distFromCenter = (sourcePart.Size.X / 2) - 4
		local surfaceY = sourcePart.Position.Y + (sourcePart.Size.Y / 2) + 0.6 -- Elevated to avoid Z-fighting
		
		local dir = (targetPos - sourcePart.Position).Unit
		pad.Position = sourcePart.Position + (dir * distFromCenter)
		pad.Position = Vector3.new(pad.Position.X, surfaceY, pad.Position.Z)
		
		pad.CFrame = CFrame.lookAt(pad.Position, Vector3.new(targetPos.X, pad.Position.Y, targetPos.Z))
		pad.Parent = Workspace

		local debounce = false
		pad.Touched:Connect(function(hit)
			if debounce then return end
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				local progress = playerProgress[player] or 0
				if progress >= levelIndexForUnlock then
					debounce = true
					
					-- Checkpoint logic: Spawn player on this platform from now on
					local checkpoint = sourcePart:FindFirstChild("CheckpointSpawn")
					if not checkpoint then
						checkpoint = Instance.new("SpawnLocation")
						checkpoint.Name = "CheckpointSpawn"
						checkpoint.Size = Vector3.new(1, 1, 1)
						checkpoint.Position = sourcePart.Position + Vector3.new(0, 15, 0) -- High up, invisible
						checkpoint.Transparency = 1
						checkpoint.CanCollide = false
						checkpoint.CanTouch = false -- No necesita detectar toques una vez creado
						checkpoint.Enabled = true
						checkpoint.Duration = 0 -- Sin escudo de protección
						
						local decal = checkpoint:FindFirstChildOfClass("Decal")
						if decal then decal:Destroy() end
						
						checkpoint.Parent = sourcePart
					end
					player.RespawnLocation = checkpoint
					
					startPath(player, pad, targetLevelIndex)
					task.wait(1)
					debounce = false
				end
			end
		end)
	end

	-- 1. Lobby -> Level 1
	makePad(lobbyPart, 0)
	
	-- 2. Level i -> Level i+1
	for i = 1, #LEVEL_CONFIGS - 1 do
		local sourcePart = levelParts[i]
		if sourcePart then
			makePad(sourcePart, i)
		end
	end
end

local function createLevels()
	print("🏃 ParkourSystem: Creating " .. #LEVEL_CONFIGS .. " levels...")
	for i, config in ipairs(LEVEL_CONFIGS) do
		local biome = BIOME_CONFIG[i]
		local pad = Templates.MasterPad:Clone()
		pad.Position = config.Position - Vector3.new(0, 10, 0)
		pad.Parent = Workspace
		
		applyBiome(pad, biome)

		local levelPlatform = Templates.MasterPlatform:Clone()
		levelPlatform.Position = config.Position
		levelPlatform.Parent = Workspace
		
		applyBiome(levelPlatform, biome)
		levelParts[i] = levelPlatform

		local levelDebounce = false
		levelPlatform.Touched:Connect(function(hit)
			if levelDebounce then return end
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				levelDebounce = true
				
				local currentProgress = playerProgress[player] or 0
				if i > currentProgress then
					if playerPaths[player] then
						playerPaths[player].LastBlock = nil
						cleanupPlayerPath(player)
					end
					
					playerProgress[player] = i
					print(player.Name .. " UNLOCKED " .. config.Name)
					
					-- Update Leaderstats
					local ls = player:FindFirstChild("leaderstats")
					if ls then
						local stageVal = ls:FindFirstChild("Stage")
						if stageVal then stageVal.Value = i end
					end
					
					player:SetAttribute("Stage", i) -- For Telemetry
					
					-- Apply immediate rewards
					applyRewards(player, i)
					
					-- Screen Notification
					task.spawn(function()
						local playerGui = player:FindFirstChild("PlayerGui")
						if playerGui then
							local msgLabel = Instance.new("TextLabel")
							msgLabel.Size = UDim2.fromScale(1, 0.2)
							msgLabel.Position = UDim2.fromScale(0, 0.4)
							msgLabel.BackgroundTransparency = 1
							msgLabel.Text = "¡NIVEL " .. i .. " DESBLOQUEADO!"
							msgLabel.TextColor3 = Color3.new(1, 1, 0)
							msgLabel.Font = Enum.Font.GothamBlack
							msgLabel.TextScaled = true
							msgLabel.Parent = playerGui
							
							-- Celebration Sound
							local revealSound = Instance.new("Sound", Workspace)
							revealSound.SoundId = "rbxassetid://12222253" -- Victory.wav
							revealSound.PlayOnRemove = true
							revealSound:Play()
							revealSound:Destroy()

							task.wait(2)
							TweenService:Create(msgLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
							task.wait(0.5)
							msgLabel:Destroy()
						end
					end)
				end
				
				task.wait(0.5)
				levelDebounce = false
			end
		end)
	end
	
	createStarterPads()

	-- Place Floating Shop Sign in the Lobby
	local function placeFloatingSign()
		print("🛒 [DEBUG] Intentando spawnear el anuncio físico en el Lobby...")
		local template = Templates:WaitForChild("FloatingShopSign", 5)
		if not template then
			warn("❌ [DEBUG] No se encontró el template FloatingShopSign")
			return
		end
		
		local sign = template:Clone()
		-- Posición en el Lobby (cerca del spawn pero sin estorbar)
		sign.Position = Vector3.new(15, 8, 15) 
		
		-- Girar el cartel para que mire hacia el Spawn (0,0,0)
		sign.CFrame = CFrame.lookAt(sign.Position, Vector3.new(0, sign.Position.Y, 0))
		
		sign.Parent = Workspace
		print("✅ [DEBUG] Anuncio físico spawneado en el Lobby: " .. tostring(sign.Position))

		-- Recoil Effect when touched
		local originalPos = sign.Position
		local debounce = false
		sign.Touched:Connect(function(hit)
			if debounce then return end
			local char = hit.Parent
			if char:FindFirstChild("Humanoid") then
				debounce = true
				
				local pushInfo = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				local returnInfo = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
				
				local pushGoal = {Position = originalPos + Vector3.new(0, 0, 1.5)}
				local returnGoal = {Position = originalPos}
				
				local t1 = TweenService:Create(sign, pushInfo, pushGoal)
				t1:Play()
				t1.Completed:Connect(function()
					task.wait(0.1)
					TweenService:Create(sign, returnInfo, returnGoal):Play()
				end)
				
				task.wait(1)
				debounce = false
			end
		end)
	end
	task.spawn(placeFloatingSign)
end

--------------------------------------------------------------------------------
-- LIFECYCLE
--------------------------------------------------------------------------------

-- Atmosphere Management Loop
task.spawn(function()
	local Lighting = game:GetService("Lighting")
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere", Lighting)
	end

	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local stage = playerProgress[player] or 1
				local atmosphereColor = ATMOSPHERE_COLORS[stage]
				if atmosphereColor then
					-- Smooth transition
					TweenService:Create(atmosphere, TweenInfo.new(2), {
						Color = atmosphereColor
					}):Play()
				end
			end
		end
		task.wait(2)
	end
end)

local function onCharacterAdded(player, char)
	cleanupPlayerPath(player)
	playerStreaks[player] = 0 -- Reset streak on death
	
	local levelIndex = playerProgress[player] or 0
	
	-- Apply rewards based on progress
	applyRewards(player, levelIndex)
end

Players.PlayerAdded:Connect(function(p)
	-- Initialize Progress from Leaderstats if it exists
	local ls = p:WaitForChild("leaderstats", 10)
	if ls then
		local stageVal = ls:WaitForChild("Stage", 5)
		if stageVal then
			playerProgress[p] = stageVal.Value
		end
	end
	
	p.CharacterAdded:Connect(function(c) onCharacterAdded(p, c) end)
end)

Players.PlayerRemoving:Connect(function(p)
	cleanupPlayerPath(p)
	playerProgress[p] = nil
end)

createLevels()


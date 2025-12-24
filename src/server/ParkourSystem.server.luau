local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local _Debris = game:GetService("Debris")
local _CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Wait for Factory
print("🏃 ParkourSystem: Waiting for Templates in ReplicatedStorage...")
local Templates = ReplicatedStorage:WaitForChild("Templates")
while not Templates:GetAttribute("PrefabReady") do task.wait(0.1) end
local _readySignal = Templates:WaitForChild("FactoryReady")
if not Templates then
	error("🛑 ParkourSystem: TIMEOUT waiting for Templates folder!")
end

print("🏃 ParkourSystem: Waiting for FactoryReady signal...")
local ready = Templates:WaitForChild("FactoryReady", 15)
if not ready then
	error("🛑 ParkourSystem: TIMEOUT waiting for FactoryReady signal!")
end
print("🏃 ParkourSystem: Factory is ready. Starting level generation...")

-- 1. Configuration: Path & Levels (EXPANDED Spacing)
local LEVEL_CONFIGS = {
	{ Position = Vector3.new(300, 45, 0), Name = "Christmas 1" },
	{ Position = Vector3.new(0, 90, 300), Name = "Christmas 2" },
	{ Position = Vector3.new(-300, 135, 0), Name = "Christmas 3" },
	{ Position = Vector3.new(0, 180, -300), Name = "Christmas 4" },
}

local BIOME_CONFIG = {
	[1] = {
		Name = "NivelNavideño1",
		Material = Enum.Material.Ice, -- Hielo resbaladizo
		Color = Color3.fromRGB(200, 240, 255), -- Blanco azulado
		ParticleColor = ColorSequence.new(Color3.fromRGB(255, 255, 255)), -- Nieve
		Texture = "rbxassetid://1265613143" -- Escarcha
	},
	[2] = {
		Name = "Christmas 2",
		Material = Enum.Material.SmoothPlastic, -- Anti-Glare Standard
		Color = Color3.fromRGB(200, 0, 0), -- Festive Red
		ParticleColor = ColorSequence.new(Color3.fromRGB(255, 255, 0)),
		Texture = "rbxassetid://585426142"
	},
	[3] = {
		Name = "Christmas 3",
		Material = Enum.Material.SmoothPlastic, -- Anti-Glare Standard
		Color = Color3.fromRGB(0, 200, 0), -- Festive Green
		ParticleColor = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Texture = "rbxassetid://244221440"
	},
	[4] = {
		Name = "Christmas 4",
		Material = Enum.Material.SmoothPlastic, -- Anti-Glare Standard
		Color = Color3.fromRGB(255, 255, 255), -- Snow White
		ParticleColor = ColorSequence.new(Color3.fromRGB(200, 200, 255)),
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
	local distance = 5 + levelIndex
	local cycleDuration = 3 -- Seconds for a full cycle
	local originalPos = block.Position
	local direction = Vector3.new(math.random(-100, 100)/100, 0, math.random(-100, 100)/100).Unit
	
	task.spawn(function()
		while block and block.Parent do
			local time = tick()
			local alpha = (math.sin(time * (math.pi * 2 / cycleDuration)) + 1) / 2 -- 0 to 1
			local nextAlpha = (math.sin((time + 0.03) * (math.pi * 2 / cycleDuration)) + 1) / 2
			
			local currentPos = originalPos + (direction * (alpha - 0.5) * distance * 2)
			local nextPos = originalPos + (direction * (nextAlpha - 0.5) * distance * 2)
			
			-- AssemblyLinearVelocity is critical for moving players with anchored parts
			local velocity = (nextPos - currentPos) / 0.03
			block.AssemblyLinearVelocity = velocity
			
			-- Update CFrame for smooth rendering
			block.CFrame = CFrame.new(currentPos)
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

local function setupChristmasAtmosphere()
	local Lighting = game:GetService("Lighting")
	
	-- Sky settings
	Lighting.ClockTime = 0 -- Midnight
	Lighting.OutdoorAmbient = Color3.fromRGB(30, 30, 60)
	Lighting.FogColor = Color3.fromRGB(20, 20, 40)
	Lighting.FogEnd = 500
	
	-- Snow Emitter (Attached to a part that follows the lobby/center)
	local snowPart = Instance.new("Part")
	snowPart.Name = "SnowEmitterPart"
	snowPart.Size = Vector3.new(1000, 1, 1000)
	snowPart.Position = Vector3.new(0, 300, 0)
	snowPart.Anchored = true
	snowPart.Transparency = 1
	snowPart.CanCollide = false
	snowPart.Parent = Workspace
	
	local snow = Instance.new("ParticleEmitter")
	snow.Name = "GlobalSnow"
	snow.Texture = "rbxassetid://242291244" -- Snow flake
	snow.Size = NumberSequence.new(0.5, 1.5)
	snow.Color = ColorSequence.new(Color3.new(1, 1, 1))
	snow.Transparency = NumberSequence.new(0, 0.5)
	snow.Lifetime = NumberRange.new(5, 10)
	snow.Rate = 500
	snow.Speed = NumberRange.new(20, 50)
	snow.VelocitySpread = 10
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.Parent = snowPart
end

setupChristmasAtmosphere()

local function createCountdown(block, duration)
	block:SetAttribute("RemainingTime", duration)

	-- Inject TimerGui if missing (Critical for custom assets)
	if not block:FindFirstChild("TimerGui") then
		local master = Templates:FindFirstChild("MasterBlock")
		local masterGui = master and master:FindFirstChild("TimerGui")
		
		if masterGui then
			local clone = masterGui:Clone()
			clone.Parent = block
		else
			-- Fallback procedural creation
			local sg = Instance.new("SurfaceGui")
			sg.Name = "TimerGui"
			sg.Face = Enum.NormalId.Top
			local tl = Instance.new("TextLabel")
			tl.Name = "TimerLabel"
			tl.Size = UDim2.fromScale(1,1); tl.BackgroundTransparency=1
			tl.TextScaled=true; tl.TextColor3=Color3.new(1,1,1)
			tl.Parent = sg
			sg.Parent = block
		end
	end

	-- Visual Update Loop
	task.spawn(function()
		local gui = block:FindFirstChild("TimerGui")
		local label = gui and gui:FindFirstChild("TimerLabel")

		while true do
			local remaining = block:GetAttribute("RemainingTime") or 0
			if remaining <= 0 or not block.Parent then break end
			
			if label then
				label.Text = string.format("%.1f", remaining)
				if remaining < 2 then label.TextColor3 = Color3.new(1,0,0) end
			end

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
	if not path then 
		return nil -- Stop generation if path was cleaned up (reached goal)
	end

	local lastBlock = originOverride or path.LastBlock
	if not lastBlock then 
		warn("🏃 ParkourSystem: spawnNextBlock failed - no origin for player " .. player.Name)
		return nil 
	end
	
	local lastPos = (lastBlock:IsA("Model") and lastBlock:GetPivot().Position) or lastBlock.Position
	
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
	
	-- 6. Clone & Setup Block (GIFT BOMB CHANCE)
	local block
	local isBomb = math.random() < 0.1
	
	if isBomb then
		local bomb = folder.BombGift:Clone()
		bomb.Name = "Path_" .. player.Name .. "_BOMB"
		bomb:PivotTo(CFrame.new(finalPos))
		bomb.Parent = Workspace
		
		local handle = bomb.PrimaryPart
		handle.Touched:Connect(function(hit)
			local char = hit.Parent
			local humrp = char:FindFirstChild("HumanoidRootPart")
			if humrp then
				local pushDir = (humrp.Position - handle.Position).Unit
				humrp.AssemblyLinearVelocity = (pushDir + Vector3.new(0, 0.5, 0)) * 100
				
				-- Explosion effect
				local exp = Instance.new("Explosion")
				exp.Position = handle.Position
				exp.BlastRadius = 0
				exp.Parent = Workspace

				-- Festive Bang
				local bang = Instance.new("Sound", Workspace)
				bang.SoundId = "rbxassetid://12222208" -- Standard Explosion
				bang.Volume = 1
				bang.PlayOnRemove = true
				bang:Play()
				bang:Destroy()
				
				task.wait(0.1)
				bomb:Destroy()
			end
		end)
		
		-- CRITICAL: If we spawn a bomb, we must automatically spawn the next valid platform
		-- so the player has a way to continue the path.
		return spawnNextBlock(player, levelIndex, bomb)
	else
		-- 6a. Select Platform Type based on Level
		local platformTemplate = folder.MasterBlock
		if levelIndex == 1 and folder:FindFirstChild("Level1Block") then
			platformTemplate = folder.Level1Block
		elseif levelIndex == 2 and folder:FindFirstChild("Level2Block") then
			platformTemplate = folder.Level2Block
		end

		block = platformTemplate:Clone()
		block.Name = "Path_" .. player.Name
		block:PivotTo(CFrame.new(finalPos))
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

		-- SPECIAL: Level 1 Christmas Features
		if levelIndex == 1 then
			-- 1. Slippery Ice Physics
			if math.random() < 0.3 then
				block.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.3, 0.5) -- Very slippery
				block.Color = Color3.fromRGB(220, 255, 255) -- Brighter ice cue
			end

			-- 2. Festive Flashing Lights (More Variety)
			local light = Instance.new("PointLight")
			light.Range = 15
			light.Brightness = 2
			light.Parent = block
			
			local colors = {
				Color3.new(1, 0, 0),   -- Red
				Color3.new(0, 1, 0),   -- Green
				Color3.fromRGB(255, 215, 0), -- Gold
				Color3.new(1, 1, 1)    -- White
			}

			task.spawn(function()
				local i = 1
				while block and block.Parent do
					light.Color = colors[i]
					i = (i % #colors) + 1
					task.wait(1)
				end
			end)

			-- 3. Snow Piles
			local numPiles = math.random(2, 4)
			for j = 1, numPiles do
				local pile = Instance.new("Part")
				pile.Name = "SnowPile"
				pile.Shape = Enum.PartType.Ball
				local size = math.random(15, 30) / 10
				pile.Size = Vector3.new(size, size * 0.5, size)
				
				-- Random pos on top of block
				local relX = (math.random() - 0.5) * block.Size.X * 0.8
				local relZ = (math.random() - 0.5) * block.Size.Z * 0.8
				pile.Position = block.Position + Vector3.new(relX, block.Size.Y/2, relZ)
				
				pile.Material = Enum.Material.Snow
				pile.Color = Color3.new(1, 1, 1)
				pile.Anchored = true
				pile.CanCollide = false
				pile.Parent = block
			end
		end
	end
	
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
				if levelIndex == 1 then
					-- Overwrite with festive bells for Level 1
					local bell = Instance.new("Sound", gem)
					bell.SoundId = "rbxassetid://134012322" -- Bell Sound
					bell.Volume = 0.8
					bell:Play()
				elseif sound then 
					sound:Play() 
				end
				
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
	local touchPart = (block:IsA("Model") and block.PrimaryPart) or block
	
	if not touchPart then return end

	touchPart.Touched:Connect(function(hit)
		if triggered then return end
		local char = hit.Parent
		local p = Players:GetPlayerFromCharacter(char)
		if p and p == player then
			-- Verify this is a generated path block
			if not block.Name:find("Path_") then return end

			local pathData = playerPaths[player]
			if pathData and pathData.LastBlock == block then
				triggered = true
				
				-- JUICE: Sound & Step-down animation
				local sound = block:FindFirstChild("JumpSound") or block:FindFirstChild("JumpSound", true)
				if sound then sound:Play() end
				
				local originalPos = (block:IsA("Model") and block:GetPivot().Position) or block.Position
				local stepInfo = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				
				if block:IsA("Model") then
					TweenService:Create(block.PrimaryPart, stepInfo, {Position = originalPos - Vector3.new(0, 0.3, 0)}):Play()
				else
					TweenService:Create(block, stepInfo, {Position = originalPos - Vector3.new(0, 0.3, 0)}):Play()
				end
				
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
	-- No reset if already on this level and first block is still alive
	local current = playerPaths[player]
	if current and current.TargetLevel == targetLevel then
		local first = current.AllBlocks[1]
		if first and first.Parent then
			return 
		end
	end

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
	print("🔍 [DIAGNÓSTICO] Esperando señal 'LobbyReady' del entorno...")
	
	-- 1. Esperar señal de sincronización (Máx 10s)
	local startTime = tick()
	while not Workspace:GetAttribute("LobbyReady") do
		if tick() - startTime > 10 then
			warn("⚠️ [TIMEOUT] LobbyReady no recibido en 10s. Procediendo con búsqueda manual...")
			break
		end
		task.wait(0.5)
	end
	print("✅ [DIAGNÓSTICO] Señal recibida o timeout superado. Buscando plataformas...")

	-- 2. Búsqueda con logs detallados
	local hexPlatform = Workspace:FindFirstChild("HexPlatform_V2")
	local lobbyPart = Workspace:FindFirstChild("Lobby")
	
	if hexPlatform then
		print("   > HexPlatform_V2 encontrada! | Clase: " .. hexPlatform.ClassName .. " | Pos: " .. tostring(hexPlatform:GetPivot().Position))
		-- Visual Debug: Resaltar la plataforma encontrada
		local h = Instance.new("Highlight")
		h.Name = "DebugHighlight_Start"
		h.FillColor = Color3.new(0,1,0) -- Verde = Éxito
		h.OutlineColor = Color3.new(1,1,1)
		h.Adornee = hexPlatform
		h.Parent = hexPlatform
		game:GetService("Debris"):AddItem(h, 5) -- Quitar a los 5s
	else
		warn("   > HexPlatform_V2 NO encontrada en Workspace.")
	end

	if lobbyPart then
		print("   > Lobby Floor encontrado. (Backup)")
	end

	if not lobbyPart and not hexPlatform then
		warn("❌ [CRITICAL ERROR] No existe suelo ni plataforma. El parkour no puede iniciar.")
		return
	end

	local function makePad(sourcePart, levelIndexForUnlock)
		local targetLevelIndex = levelIndexForUnlock + 1
		local biome = BIOME_CONFIG[targetLevelIndex]
		local targetPos = LEVEL_CONFIGS[targetLevelIndex].Position
		
		local pad = Templates.MasterPad:Clone()
		pad.Name = "StarterPad_Level" .. targetLevelIndex
		
		applyBiome(pad, biome)

		-- Handle both Parts and Models for sourcePart
		local sourceSize = (sourcePart:IsA("Model") and sourcePart:GetExtentsSize()) or sourcePart.Size
		local sourcePos = (sourcePart:IsA("Model") and sourcePart:GetPivot().Position) or sourcePart.Position

		local distFromCenter = (sourceSize.X / 2) -- Center of pad exactly on the edge
		local surfaceY = sourcePos.Y + (sourceSize.Y / 2) + 0.8 -- Slightly higher to be safe
		
		local dir = (targetPos - sourcePos).Unit
		local finalPos = sourcePos + (dir * distFromCenter)
		finalPos = Vector3.new(finalPos.X, surfaceY, finalPos.Z)
		
		pad.Position = finalPos
		pad.CFrame = CFrame.lookAt(finalPos, Vector3.new(targetPos.X, finalPos.Y, targetPos.Z))
		pad.Parent = Workspace
		
		print("📍 [DEBUG] StarterPad Level "..targetLevelIndex.." spawned at: "..tostring(finalPos))

		local activeDebounces = {}
		pad.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player and not activeDebounces[player] then
				local progress = playerProgress[player] or 0
				if progress >= levelIndexForUnlock then
					activeDebounces[player] = true
					
					-- Checkpoint logic: Spawn player on this platform from now on
					local checkpoint = sourcePart:FindFirstChild("CheckpointSpawn")
					if not checkpoint then
						checkpoint = Instance.new("SpawnLocation")
						checkpoint.Name = "CheckpointSpawn"
						checkpoint.Size = Vector3.new(1, 1, 1)
						-- Fix: Use GetPivot() for Models
						local sPos = (sourcePart:IsA("Model") and sourcePart:GetPivot().Position) or sourcePart.Position
						checkpoint.Position = sPos + Vector3.new(0, 15, 0) -- High up, invisible
						checkpoint.Transparency = 1
						checkpoint.CanCollide = false
						checkpoint.CanTouch = false 
						checkpoint.Enabled = true
						checkpoint.Duration = 0 
						
						local decal = checkpoint:FindFirstChildOfClass("Decal")
						if decal then decal:Destroy() end
						
						checkpoint.Parent = sourcePart
					end
					player.RespawnLocation = checkpoint
					
					startPath(player, pad, targetLevelIndex)
					task.wait(1)
					activeDebounces[player] = false
				end
			end
		end)
	end

	-- 1. Lobby -> Level 1 (Prioritize the specific Platform model if it exists)
	local startAnchor = hexPlatform or lobbyPart
	makePad(startAnchor, 0)
	
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
				
				-- DETENER GENERACIÓN: Limpiar el camino actual al llegar a la meta
				if playerPaths[player] then
					cleanupPlayerPath(player)
					playerPaths[player] = nil
				end

				local currentProgress = playerProgress[player] or 0
				if i > currentProgress then
					playerProgress[player] = i
					print(player.Name .. " UNLOCKED " .. config.Name)
					
					-- Checkpoint logic: Spawn player on this platform from now on
					local checkpoint = levelPlatform:FindFirstChild("CheckpointSpawn")
					if not checkpoint then
						checkpoint = Instance.new("SpawnLocation")
						checkpoint.Name = "CheckpointSpawn"
						checkpoint.Size = Vector3.new(1, 1, 1)
						checkpoint.Position = levelPlatform.Position + Vector3.new(0, 5, 0)
						checkpoint.Transparency = 1
						checkpoint.CanCollide = false
						checkpoint.Enabled = true
						checkpoint.Duration = 0
						checkpoint.Parent = levelPlatform
						
						local decal = checkpoint:FindFirstChildOfClass("Decal")
						if decal then decal:Destroy() end
					end
					player.RespawnLocation = checkpoint

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
		sign.Position = Vector3.new(0, 10, -25) 
		
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
-- Atmosphere Management (Server-Side Default)
-- Note: Dynamic per-player atmosphere should be handled on Client to avoid conflicts.
task.spawn(function()
	local Lighting = game:GetService("Lighting")
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere", Lighting)
	end

	-- Set a default baseline color
	atmosphere.Color = Color3.fromRGB(150, 180, 255)
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


-- CharizardVisuals.client.luau
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local TAG_NAME = "Charivoxel"

print("🔥 CharizardVisuals: Initialized. Watching for " .. TAG_NAME)

local function setupCharizardVisuals(model)
	print("🔥 CharizardVisuals: Found new Charivoxel to animate!")
	
	local neck = model:WaitForChild("Neck")
	local neckWeld = neck:WaitForChild("Motor6D")
	
	local jaw = model:WaitForChild("Jaw")
	local jawWeld = jaw:WaitForChild("Motor6D")
	
	local tail1 = model:WaitForChild("Tail1")
	local tail1Weld = tail1:WaitForChild("Motor6D")
	
	local tail2 = model:WaitForChild("Tail2")
	local tail2Weld = tail2:WaitForChild("Motor6D")
	
	local tailTip = model:WaitForChild("TailTip")
	local tailTipWeld = tailTip:WaitForChild("Motor6D")
	
	local wingPivotL = model:WaitForChild("WingPivotL")
	local wingLWeld = wingPivotL:WaitForChild("Motor6D")
	
	local wingPivotR = model:WaitForChild("WingPivotR")
	local wingRWeld = wingPivotR:WaitForChild("Motor6D")
	
	local head = model:WaitForChild("Head", 5) -- Timeout just in case

	-- Initial Offsets
	local neckC0 = CFrame.new(0, 2.2, 0.2) * CFrame.Angles(math.rad(10), 0, 0)
	local tail1C0 = CFrame.new(0, -1.5, -1.2) * CFrame.Angles(math.rad(-10), 0, 0)
	local wingLC0 = CFrame.new(-1.5, 1.5, -1)
	local wingRC0 = CFrame.new(1.5, 1.5, -1)

	local time = 0
	local connection
	
	connection = RunService.RenderStepped:Connect(function(dt)
		if not model.Parent then 
			connection:Disconnect() 
			return 
		end
		
		time += dt
		
		-- 1. SMOOTH WING FLAP (60 FPS)
		local wingFlap = math.sin(time * 3) * 0.5
		wingLWeld.C0 = wingLC0 * CFrame.Angles(0, 0, -0.5 + wingFlap)
		wingRWeld.C0 = wingRC0 * CFrame.Angles(0, 0, 0.5 - wingFlap)
		
		-- 2. ORGANIC TAIL SWAY (Compound Sine)
		local tailWave = math.sin(time * 2) * 0.2
		local tailTipWave = math.sin(time * 2 - 0.5) * 0.3 -- Lagged wave
		
		tail1Weld.C0 = tail1C0 * CFrame.Angles(0, tailWave, 0)
		tail2Weld.C0 = CFrame.new(0, -0.5, -2.5) * CFrame.Angles(0, tailWave * 1.2, 0)
		tailTipWeld.C0 = CFrame.new(0, 0.5, -2.5) * CFrame.Angles(math.rad(20), tailTipWave, 0)
		
		-- 3. NECK BREATHING
		neckWeld.C0 = neckC0 * CFrame.Angles(math.sin(time) * 0.05, 0, 0)
		
		-- 4. LOCAL HEAD TRACKING
		if head and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (player.Character.HumanoidRootPart.Position - head.Position).Magnitude
			if dist < 40 then
				local targetPos = player.Character.HumanoidRootPart.Position
				local lookCFrame = CFrame.lookAt(head.Position, targetPos)
				local relativeLook = head.Parent:GetPivot():Inverse() * lookCFrame
				
				-- Clamp angles to prevent breaking neck
				local rx, ry, rz = relativeLook:ToOrientation()
				ry = math.clamp(ry, -1, 1)
				rx = math.clamp(rx, -0.5, 0.5)
				
				local limitedLook = CFrame.fromOrientation(rx, ry, 0)
				neckWeld.C1 = limitedLook:Inverse() * CFrame.new(0, 1.25, 0.3)
			else
				-- Lerp back to center
				neckWeld.C1 = neckWeld.C1:Lerp(CFrame.new(0, 1.25, 0.3), 0.1)
			end
		end
	end)
	
	-- ROAR EVENT LISTENER
	model:GetAttributeChangedSignal("IsRoaring"):Connect(function()
		local isRoaring = model:GetAttribute("IsRoaring")
		
		if isRoaring then
			-- Open Jaw Animation
			TweenService:Create(jawWeld, TweenInfo.new(0.3), {C0 = CFrame.new(0, -0.8, 0.5) * CFrame.Angles(math.rad(45), 0, 0)}):Play()
			
			-- FIRE BREATH PARTICLES (Client Side = Smoother)
			local breath = Instance.new("ParticleEmitter")
			breath.Name = "FireBreathClient"
			breath.Texture = "rbxassetid://6201389270"
			breath.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
				ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 50, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 0))
			})
			breath.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 5)
			})
			breath.Lifetime = NumberRange.new(1.5, 2.5)
			breath.Rate = 150
			breath.Speed = NumberRange.new(25, 40)
			breath.SpreadAngle = Vector2.new(10, 10)
			breath.Acceleration = Vector3.new(0, 2, 0)
			breath.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.2),
				NumberSequenceKeypoint.new(1, 1)
			})
			breath.Parent = head
			
			-- Sound
			local roarSound = Instance.new("Sound")
			roarSound.SoundId = "rbxassetid://6201391963" -- Dragon Roar
			roarSound.Volume = 1.5
			roarSound.RollOffMaxDistance = 100
			roarSound.Parent = head
			roarSound:Play()
			
			task.delay(2.5, function()
				breath.Enabled = false
				Debris:AddItem(breath, 3)
				Debris:AddItem(roarSound, 3)
				-- Close Jaw
				TweenService:Create(jawWeld, TweenInfo.new(0.5), {C0 = CFrame.new(0, -0.8, 0.5)}):Play()
			end)
		end
	end)
end

-- Initialize for existing and new bots
for _, bot in ipairs(CollectionService:GetTagged(TAG_NAME)) do
	setupCharizardVisuals(bot)
end

CollectionService:GetInstanceAddedSignal(TAG_NAME):Connect(setupCharizardVisuals)

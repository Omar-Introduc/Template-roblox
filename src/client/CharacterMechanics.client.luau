-- src/client/CharacterMechanics.client.luau
--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character: Model? = player.Character
local humanoid: Humanoid?
local rootPart: BasePart?

local hasDoubleJumped = false

-- Fly Variables
local isFlying = false
local flyLv: LinearVelocity?
local flyAo: AlignOrientation?
local flyAtt: Attachment?
local CAM_SPEED = 50

-- Connection management
local characterConnections = {}

local function cleanConnections()
	for _, conn in characterConnections do
		if typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		end
	end
	table.clear(characterConnections)
end

local function cleanFlyPhysics()
	if flyLv then flyLv:Destroy(); flyLv = nil end
	if flyAo then flyAo:Destroy(); flyAo = nil end
	if flyAtt then flyAtt:Destroy(); flyAtt = nil end
end

local function stopFlying()
	isFlying = false
	cleanFlyPhysics()
	if humanoid then humanoid.PlatformStand = false end
end

local function startFlying()
	if isFlying then return end
	if not rootPart or not humanoid then return end
	isFlying = true

	-- Create Attachment
	local att = Instance.new("Attachment")
	att.Name = "FlyAttachment"
	att.Parent = rootPart
	flyAtt = att

	-- Create LinearVelocity
	local lv = Instance.new("LinearVelocity")
	lv.Name = "FlyLinearVelocity"
	lv.Attachment0 = att
	lv.VectorVelocity = Vector3.zero
	lv.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	lv.MaxForce = math.huge
	lv.Parent = rootPart
	flyLv = lv

	-- Create AlignOrientation
	local ao = Instance.new("AlignOrientation")
	ao.Name = "FlyAlignOrientation"
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.MaxTorque = math.huge
	ao.Responsiveness = 50 -- Snappy rotation
	ao.CFrame = rootPart.CFrame
	ao.Parent = rootPart
	flyAo = ao

	humanoid.PlatformStand = true
end

local function updateFlyPhysics()
	if not isFlying or not flyLv or not flyAo or not flyAtt then return end

	local camCF = Workspace.CurrentCamera.CFrame
	local moveDir = Vector3.zero

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camCF.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camCF.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camCF.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camCF.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end

	if moveDir.Magnitude > 0 then
		moveDir = moveDir.Unit * CAM_SPEED
	end

	flyLv.VectorVelocity = moveDir
	flyAo.CFrame = camCF
end

local function onJumpRequest()
	local char = character
	local hum = humanoid
	local root = rootPart
	if not char or not hum or not root or hum.Health <= 0 then return end

	-- Check Buffs with strict type casting
	local flyEndAttr = char:GetAttribute("Buff_Fly_End")
	local hasFly = typeof(flyEndAttr) == "number" and os.time() < (flyEndAttr :: number)

	-- Double Jump can be a temporary Buff or a permanent Ownership attribute
	local hasDoubleJump = char:GetAttribute("Buff_DoubleJump") == true or player:GetAttribute("Owns_DoubleJump") == true

	local state = hum:GetState()

	if hasFly then
		if state == Enum.HumanoidStateType.Freefall and not isFlying then
			startFlying()
		end
	elseif hasDoubleJump then
		-- Only allow double jump if in air, not already double jumped, and not currently flying
		if (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping) 
			and not hasDoubleJumped 
			and not isFlying 
		then
			hasDoubleJumped = true
			
			-- Reset vertical velocity for a consistent jump experience
			local vel = root.AssemblyLinearVelocity
			
			-- Calculate jump power
			local jumpPower = 0
			if hum.UseJumpPower then
				jumpPower = hum.JumpPower
			else
				jumpPower = math.sqrt(2 * Workspace.Gravity * hum.JumpHeight)
			end

			-- Apply the jump impulse (slight extra boost for double jump feedback)
			root.AssemblyLinearVelocity = Vector3.new(vel.X, jumpPower * 1.1, vel.Z)
			
			-- Visual Feedback: Small burst of particles or sound could go here
			local p = Instance.new("ParticleEmitter")
			p.Transparency = NumberSequence.new(0.5, 1)
			p.Size = NumberSequence.new(0.5, 0)
			p.Lifetime = NumberRange.new(0.2, 0.5)
			p.Rate = 100
			p.Speed = NumberRange.new(5, 10)
			p.Parent = root
			task.delay(0.2, function() p.Enabled = false end)
			game:GetService("Debris"):AddItem(p, 1)

			-- Force state change to trigger animations
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end

local function setupCharacter(newChar: Model)
	character = newChar
	local hum = newChar:WaitForChild("Humanoid") :: Humanoid
	local root = newChar:WaitForChild("HumanoidRootPart") :: BasePart
	
	humanoid = hum
	rootPart = root
	
	isFlying = false
	hasDoubleJumped = false
	
	cleanFlyPhysics()
	cleanConnections()

	-- State management connections
	table.insert(characterConnections, hum.StateChanged:Connect(function(_, new: Enum.HumanoidStateType)
		if new == Enum.HumanoidStateType.Landed then
			hasDoubleJumped = false
			if isFlying then stopFlying() end
		end
	end))

	table.insert(characterConnections, hum.Died:Connect(function()
		stopFlying()
		cleanConnections()
		character = nil
		humanoid = nil
		rootPart = nil
	end))
end

-- Global connections
UserInputService.JumpRequest:Connect(onJumpRequest)

RunService.Heartbeat:Connect(function()
	local char = character
	if not char or not isFlying then return end
	
	local flyEndAttr = char:GetAttribute("Buff_Fly_End")
	if typeof(flyEndAttr) ~= "number" or os.time() > (flyEndAttr :: number) then
		stopFlying()
	else
		updateFlyPhysics()
	end
end)

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	setupCharacter(player.Character)
end



-- src/client/CharacterMechanics.client.luau
--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

local canDoubleJump = false
local hasDoubleJumped = false

-- Fly Variables
local isFlying = false
local flyLv: LinearVelocity?
local flyAo: AlignOrientation?
local flyAtt: Attachment?
local CAM_SPEED = 50

local function getCharacter()
	return player.Character
end

local function cleanFlyPhysics()
	if flyLv then flyLv:Destroy() flyLv = nil end
	if flyAo then flyAo:Destroy() flyAo = nil end
	if flyAtt then flyAtt:Destroy() flyAtt = nil end
end

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
	isFlying = false
	hasDoubleJumped = false
	canDoubleJump = false
	cleanFlyPhysics()
end)

local function stopFlying()
	isFlying = false
	cleanFlyPhysics()
	if humanoid then humanoid.PlatformStand = false end
end

local function startFlying()
	if isFlying then return end
	if not rootPart then return end
	isFlying = true

	-- Create Attachment
	flyAtt = Instance.new("Attachment")
	flyAtt.Name = "FlyAttachment"
	flyAtt.Parent = rootPart

	-- Create LinearVelocity
	flyLv = Instance.new("LinearVelocity")
	flyLv.Name = "FlyLinearVelocity"
	flyLv.Attachment0 = flyAtt
	flyLv.VectorVelocity = Vector3.zero
	flyLv.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	flyLv.MaxForce = math.huge
	flyLv.Parent = rootPart

	-- Create AlignOrientation
	flyAo = Instance.new("AlignOrientation")
	flyAo.Name = "FlyAlignOrientation"
	flyAo.Mode = Enum.OrientationAlignmentMode.OneAttachment
	flyAo.Attachment0 = flyAtt
	flyAo.MaxTorque = math.huge
	flyAo.Responsiveness = 50 -- Snappy rotation
	flyAo.CFrame = rootPart.CFrame
	flyAo.Parent = rootPart

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

UserInputService.JumpRequest:Connect(function()
	if not character or not humanoid or humanoid.Health <= 0 then return end

	-- Check Fly Buff
	local flyEnd = character:GetAttribute("Buff_Fly_End")
	local hasFly = flyEnd and os.time() < flyEnd

	-- Check Double Jump Buff
	local hasDoubleJump = character:GetAttribute("Buff_DoubleJump")

	local state = humanoid:GetState()

	if hasFly then
		-- Si tiene vuelo y salta en el aire -> Activar Vuelo
		if state == Enum.HumanoidStateType.Freefall and not isFlying then
			startFlying()
		end
	elseif hasDoubleJump then
		-- Doble Salto
		if state == Enum.HumanoidStateType.Freefall and not hasDoubleJumped and canDoubleJump then
			hasDoubleJumped = true
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

			-- Aplicar impulso vertical
			local jumpPower = humanoid.UseJumpPower and humanoid.JumpPower or humanoid.JumpHeight * 5 -- Approx logic if Power not used
			if not humanoid.UseJumpPower then
				-- Convert Height to Velocity: v = sqrt(2*g*h)
				jumpPower = math.sqrt(2 * Workspace.Gravity * humanoid.JumpHeight)
			end

			local vel = rootPart.AssemblyLinearVelocity
			rootPart.AssemblyLinearVelocity = Vector3.new(vel.X, jumpPower, vel.Z)
		end
	end
end)

humanoid.StateChanged:Connect(function(old, new)
	if new == Enum.HumanoidStateType.Landed then
		canDoubleJump = true
		hasDoubleJumped = false
		if isFlying then stopFlying() end
	elseif new == Enum.HumanoidStateType.Freefall then
		-- Permitir doble salto poco después de caer
		task.wait(0.1)
		canDoubleJump = true
	end
end)

RunService.Heartbeat:Connect(function()
	-- Validar expiración de vuelo y actualizar física
	local flyEnd = character:GetAttribute("Buff_Fly_End")

	if isFlying then
		if not flyEnd or os.time() > flyEnd then
			stopFlying()
		else
			updateFlyPhysics()
		end
	end
end)

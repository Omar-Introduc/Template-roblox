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
local flyBv: BodyVelocity?
local flyBg: BodyGyro?
local CAM_SPEED = 50

local function getCharacter()
	return player.Character
end

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
	isFlying = false
	hasDoubleJumped = false
	canDoubleJump = false
end)

local function stopFlying()
	isFlying = false
	if flyBv then flyBv:Destroy() flyBv = nil end
	if flyBg then flyBg:Destroy() flyBg = nil end
	if humanoid then humanoid.PlatformStand = false end
end

local function startFlying()
	if isFlying then return end
	isFlying = true

	flyBv = Instance.new("BodyVelocity")
	flyBv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyBv.Velocity = Vector3.zero
	flyBv.Parent = rootPart

	flyBg = Instance.new("BodyGyro")
	flyBg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flyBg.CFrame = rootPart.CFrame
	flyBg.Parent = rootPart

	humanoid.PlatformStand = true
end

local function updateFlyPhysics()
	if not isFlying or not flyBv or not flyBg then return end

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

	flyBv.Velocity = moveDir
	flyBg.CFrame = camCF
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

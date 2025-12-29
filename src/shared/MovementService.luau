--!strict
local MovementService = {}

local CONFIG = {
	AMPLITUD_MAXIMA = 10,
	VELOCIDAD_OSCILACION = 2
}

type MovementConfig = {
	CentroZ: number,
	Amplitud: number?,
	Velocidad: number?
}

function MovementService.StartMovement(platform: Instance, config: MovementConfig)
	if platform.Name == "Plataforma_1" then return end

	local mainPart = platform:IsA("Model") and platform.PrimaryPart or platform
	if not mainPart or not mainPart:IsA("BasePart") then return end

	-- Configurar Attachments y Constraints
	local attachment = mainPart:FindFirstChild("MoveAttachment") or Instance.new("Attachment")
	attachment.Name = "MoveAttachment"
	attachment.Parent = mainPart

	local alignPos = mainPart:FindFirstChild("PlatformAlign") or Instance.new("AlignPosition") --[[@as AlignPosition]]
	alignPos.Name = "PlatformAlign"
	alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPos.Attachment0 = attachment
	alignPos.MaxForce = 1000000
	alignPos.Responsiveness = 15
	alignPos.Enabled = true
	alignPos.Parent = mainPart

	local alignOri = mainPart:FindFirstChild("PlatformOri") or Instance.new("AlignOrientation") --[[@as AlignOrientation]]
	alignOri.Name = "PlatformOri"
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.Attachment0 = attachment
	alignOri.CFrame = mainPart.CFrame
	alignOri.MaxTorque = 1000000
	alignOri.Responsiveness = 200
	alignOri.Enabled = true
	alignOri.Parent = mainPart

	mainPart.Anchored = false

	-- Loop de movimiento
	task.spawn(function()
		local tiempo = 0
		local xOriginal = mainPart.Position.X
		local yOriginal = mainPart.Position.Y
		local centroZ = config.CentroZ
		local amplitud = config.Amplitud or CONFIG.AMPLITUD_MAXIMA
		local velocidad = config.Velocidad or CONFIG.VELOCIDAD_OSCILACION

		while mainPart and mainPart.Parent and alignPos.Enabled do
			local dt = task.wait()
			tiempo += dt

			local nuevoZ = centroZ + (math.sin(tiempo * velocidad) * amplitud)
			alignPos.Position = Vector3.new(xOriginal, yOriginal, nuevoZ)

			-- Detener si la plataforma fue activada (color negro)
			-- Nota: Esto asume que el GameManager cambia el color.
			-- Idealmente esto sería un evento o una llamada StopMovement.
			if platform:GetAttribute("Triggered") == true and mainPart.Color == Color3.new(0,0,0) then
				break
			end
		end

		if alignPos then alignPos.Enabled = false end
		if alignOri then alignOri.Enabled = false end
	end)
end

function MovementService.StopMovement(platform: Instance)
	local mainPart = platform:IsA("Model") and platform.PrimaryPart or platform
	if not mainPart or not mainPart:IsA("BasePart") then return end

	local alignPos = mainPart:FindFirstChild("PlatformAlign") --[[@as AlignPosition]]
	if alignPos then alignPos.Enabled = false end

	local alignOri = mainPart:FindFirstChild("PlatformOri") --[[@as AlignOrientation]]
	if alignOri then alignOri.Enabled = false end
end

return MovementService

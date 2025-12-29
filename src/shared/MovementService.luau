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

	-- Server-Side: Only set attributes for State
	-- The client will read these and handle the visual interpolation
	local xOriginal = mainPart.Position.X
	local yOriginal = mainPart.Position.Y
	local centroZ = config.CentroZ
	local amplitud = config.Amplitud or CONFIG.AMPLITUD_MAXIMA
	local velocidad = config.Velocidad or CONFIG.VELOCIDAD_OSCILACION

	platform:SetAttribute("MovementOriginX", xOriginal)
	platform:SetAttribute("MovementOriginY", yOriginal)
	platform:SetAttribute("MovementCenterZ", centroZ)
	platform:SetAttribute("MovementAmplitude", amplitud)
	platform:SetAttribute("MovementSpeed", velocidad)
	platform:SetAttribute("MovementStartTime", os.clock())
	platform:SetAttribute("MovementActive", true)

	-- Ensure it's anchored on Server so it doesn't fall physically
	mainPart.Anchored = true
end

function MovementService.StopMovement(platform: Instance)
	platform:SetAttribute("MovementActive", false)
end

return MovementService

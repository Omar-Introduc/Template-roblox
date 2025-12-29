--!strict
local PlatformSpawner = {}
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Data-Driven Design: Use GameConfig
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

function PlatformSpawner.Reset()
	-- Clean up platforms from a hypothetical container or reset state if needed.
	-- Since this is stateless utility, we mainly reset if we were tracking something.
	-- For now, this is a placeholder to satisfy GameManager calls.
	print("PlatformSpawner: Reset called")
end

function PlatformSpawner.SpawnNext(currentPlatform: Instance, estructuras: Folder, centroGlobalZ: number)
	local currentNum = 1
	if currentPlatform then
		currentNum = tonumber(string.match(currentPlatform.Name, "%d+")) or 1
	end

	local nextNum = currentNum + 1
	local nextName = "Plataforma_" .. nextNum

	if estructuras:FindFirstChild(nextName) then return end

	local prefabs = ServerStorage:WaitForChild("Prefabs")
	local template = prefabs:FindFirstChild("PlataformaTemplate") --[[@as Model | BasePart]]
	if not template then
		warn("⚠️ [PlatformSpawner] No se encontró 'PlataformaTemplate' en ServerStorage/Prefabs")
		return
	end

	local newPlatform = template:Clone()
	newPlatform.Name = nextName

	-- Calculo de Distancia Dinámico
	local sizeX = 0
	if template:IsA("Model") then
		sizeX = template:GetExtentsSize().X
	elseif template:IsA("BasePart") then
		sizeX = template.Size.X
	end

	-- Dificultad progresiva suave
	local incrementoDificultad = math.min(nextNum * 0.1, 5)
	local distanciaFinal = sizeX + GameConfig.ESPACIO_ENTRE_BORDES + incrementoDificultad

	local currentPivot = currentPlatform:GetPivot()
	local templatePivot = template:GetPivot()
	local nuevaPosicion = Vector3.new(currentPivot.Position.X + distanciaFinal, templatePivot.Position.Y, centroGlobalZ)

	newPlatform:PivotTo(CFrame.new(nuevaPosicion) * templatePivot.Rotation)
	newPlatform.Parent = estructuras

	return newPlatform
end

return PlatformSpawner

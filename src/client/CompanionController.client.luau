--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
-- local TweenService = game:GetService("TweenService") -- Unused

local player = Players.LocalPlayer
local CompanionController = {}

-- Configuración de efectos
local RARITY_COLORS = {
	Common = Color3.fromRGB(200, 200, 200),
	Rare = Color3.fromRGB(0, 150, 255),
	Mystic = Color3.fromRGB(255, 215, 0)
}

local function applyRarityEffects(beast: Model, rarity: string)
	local color = RARITY_COLORS[rarity] or RARITY_COLORS.Common
	local mainPart = beast.PrimaryPart or beast:FindFirstChildWhichIsA("BasePart")
	
	if not mainPart then return end
	
	-- Efecto de Highlight
	-- Efecto de Highlight
	local existingHighlight = beast:FindFirstChild("RarityHighlight")
    local highlight: Highlight
    
    if existingHighlight and existingHighlight:IsA("Highlight") then
        highlight = existingHighlight
    else
        highlight = Instance.new("Highlight")
        highlight.Name = "RarityHighlight"
        highlight.Parent = beast
    end
    
	highlight.FillTransparency = 1
	highlight.OutlineColor = color
	highlight.OutlineTransparency = 0.2
	
	-- Partículas solo para Mystic
	if rarity == "Mystic" then
		local particles = mainPart:FindFirstChild("MysticParticles")
		if not particles then
			local emitter = Instance.new("ParticleEmitter")
			emitter.Name = "MysticParticles"
			emitter.Texture = "rbxassetid://244721535" -- Estrellas/Destellos genéricos
			emitter.Color = ColorSequence.new(color)
			emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
			emitter.Lifetime = NumberRange.new(0.5, 1)
			emitter.Rate = 10
			emitter.Speed = NumberRange.new(1, 2)
			emitter.SpreadAngle = Vector2.new(360, 360)
			emitter.Parent = mainPart
		end
	end
end

local function updateCompanion(character: Model)
	local beast = character:FindFirstChild("ActiveCompanion") :: Model
	if not beast then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not hrp then return end
	
	local mainPart = beast.PrimaryPart or beast:FindFirstChildWhichIsA("BasePart")
	if not mainPart then return end
	
	-- Leer rareza
	local rarity = beast:GetAttribute("Rarity")
    local rarityString = if typeof(rarity) == "string" then rarity else "Common"
	
	-- Aplicar efectos si es nuevo
	if not beast:GetAttribute("EffectsApplied") then
		applyRarityEffects(beast, rarityString)
		beast:SetAttribute("EffectsApplied", true)
	end
	
	-- Animación de Flote (Oscilación)
	local time = os.clock()
	local bobbleY = math.sin(time * 3) * 0.5
	local bobbleX = math.cos(time * 2) * 0.3
	
	-- Offset objetivo: A la derecha y un poco atrás
	local targetOffset = CFrame.new(4 + bobbleX, 2 + bobbleY, 2)
	
	-- Rotación lenta sobre su propio eje (1 radián por segundo aprox)
	local rotation = CFrame.Angles(0, time * 1, 0)
	
	-- Lerp suave para mover el modelo
	local currentCF = mainPart.CFrame
	-- Calculamos el objetivo final combinando la posición relativa al jugador + la rotación propia
	local targetCF = hrp.CFrame * targetOffset * rotation
	
	-- Usar Lerp para suavizar el movimiento (0.1 alpha)
	mainPart.CFrame = currentCF:Lerp(targetCF, 0.1)
end

-- Bucle principal
RunService.RenderStepped:Connect(function()
	if player.Character then
		updateCompanion(player.Character)
	end
end)

print("🐾 [CompanionController] Sistema de mascotas iniciado.")

return CompanionController

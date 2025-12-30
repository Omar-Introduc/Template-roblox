--!strict
local FeedbackService = {}

-- Tipado Estricto
type BindableEvent = Instance & {
	Event: RBXScriptSignal
}

function FeedbackService.CreateCountdown(parentPart: BasePart, duration: number)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "CountdownGui"
	sg.Face = Enum.NormalId.Top
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 50
	sg.AlwaysOnTop = true -- Para que el jugador lo vea siempre sobre la plataforma
	sg.MaxDistance = 50 -- Solo visible si estás cerca

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.Text = string.format("%.1f", duration)
	text.Parent = sg
	sg.Parent = parentPart

	task.spawn(function()
		local timeLeft = duration
		while timeLeft > 0 do
			if not parentPart or not parentPart.Parent then break end
			
			timeLeft = math.max(0, timeLeft - 0.1)
			text.Text = string.format("%.1f", timeLeft)
			
			-- Efecto de color: Cambia a rojo cuando queda menos de 1 segundo
			if timeLeft <= 1 then
				text.TextColor3 = Color3.fromRGB(255, 50, 50)
				-- Pequeño efecto de "latido" o escala
				local scale = 1 + (math.sin(os.clock() * 15) * 0.1)
				text.Size = UDim2.new(scale, 0, scale, 0)
				text.Position = UDim2.new((1-scale)/2, 0, (1-scale)/2, 0)
			end
			
			task.wait(0.1)
		end
		if sg then sg:Destroy() end
	end)

	return sg
end

-- Inicialización y Escucha de Eventos (Observer Pattern)
function FeedbackService.Init(platformTriggeredEvent: RBXScriptSignal)
	platformTriggeredEvent:Connect(function(platform: Instance, duration: number)
		local mainPart = platform:IsA("Model") and platform.PrimaryPart or platform
		if mainPart and mainPart:IsA("BasePart") then
			FeedbackService.CreateCountdown(mainPart, duration)
		end
	end)
	print("✅ [FeedbackService] Listening to PlatformTriggered event.")
end

return FeedbackService

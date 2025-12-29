--!strict
local FeedbackService = {}

function FeedbackService.CreateCountdown(parentPart: BasePart, duration: number)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "CountdownGui"
	sg.Face = Enum.NormalId.Top
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 50
	sg.AlwaysOnTop = false

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.Text = tostring(duration)
	text.Parent = sg
	sg.Parent = parentPart

	task.spawn(function()
		for i = duration, 1, -1 do
			if not parentPart or not parentPart.Parent then break end
			text.Text = tostring(i)
			task.wait(1)
		end
		if sg then sg:Destroy() end
	end)

	return sg
end

return FeedbackService

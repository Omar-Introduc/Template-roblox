local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local function setupBlockVFX(block)
	local surfaceGui = block:WaitForChild("TimerGui", 10)
	if not surfaceGui then return end
	local label = surfaceGui:WaitForChild("TimerLabel", 10)
	if not label then return end

	-- 1. Appearance Animation (Client-side Juice)
	local finalSize = block.Size
	local finalTransparency = block.Transparency
	block.Size = Vector3.new(0, 0, 0)
	block.Transparency = 1
	
	local tween = TweenService:Create(block, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = finalSize,
		Transparency = finalTransparency
	})
	tween:Play()
	
	tween.Completed:Connect(function()
		local particles = block:FindFirstChild("BiomeEffect")
		if particles then
			particles:Emit(30) -- Particle Burst!
		end
	end)

	-- 2. Local Timer Loop
	task.spawn(function()
		while block:IsDescendantOf(game) do
			local remaining = block:GetAttribute("RemainingTime") or 0
			if remaining <= 0 then 
				label.Visible = false
				break 
			end

			label.Text = string.format("%.1f", remaining)

			-- Color & Visibility Logic
			if remaining <= 1 then
				label.TextColor3 = Color3.fromRGB(255, 0, 0)
				label.Visible = (math.floor(tick() * 10) % 2 == 0)
			elseif remaining <= 2 then
				label.TextColor3 = Color3.fromRGB(255, 255, 0)
				label.Visible = true
			else
				label.TextColor3 = Color3.new(1, 1, 1)
				label.Visible = true
			end

			-- Shake Effect (< 1.5s)
			if remaining <= 1.5 then
				local shake = (math.random() - 0.5) * 0.05
				label.Position = UDim2.fromScale(0.5 + shake, 0.5 + shake)
			else
				label.Position = UDim2.fromScale(0.5, 0.5)
			end

			task.wait(0.05)
		end
	end)
end

-- Monitor existing and new blocks
for _, block in ipairs(CollectionService:GetTagged("Crystal")) do
	setupBlockVFX(block)
end

CollectionService:GetInstanceAddedSignal("Crystal"):Connect(setupBlockVFX)

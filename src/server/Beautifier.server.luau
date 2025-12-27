local DEBUG_DISCOVERY_MODE = true

local seenUnknownMeshes = {}

-- Define style rules here
-- Each rule needs a 'name' (string to find) and properties to apply
local STYLE_RULES = {
	{
		name = "Rubi",
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 0, 0),
		Transparency = 0.2
	},
	{
		name = "AncientRock",
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(100, 100, 100)
	},
	-- Add more rules here as discovered
}

local function applyStyle(instance)
	-- Optimization: Only process BaseParts (Parts, MeshParts, etc)
	if not instance:IsA("BasePart") then
		return
	end

	-- Avoid double processing
	if instance:GetAttribute("IsEnhanced") then
		return
	end

	local foundMatch = false
	local meshName = instance.Name

	for _, rule in ipairs(STYLE_RULES) do
		if string.find(meshName, rule.name) then
			-- Apply styles
			if rule.Material then
				instance.Material = rule.Material
			end
			if rule.Color then
				instance.Color = rule.Color
			end
			if rule.Transparency then
				instance.Transparency = rule.Transparency
			end

			foundMatch = true
			break -- Stop after first match
		end
	end

	-- Mark as processed so we don't do it again
	instance:SetAttribute("IsEnhanced", true)

	-- Discovery Mode Logic
	if DEBUG_DISCOVERY_MODE and not foundMatch and instance:IsA("MeshPart") then
		if not seenUnknownMeshes[meshName] then
			seenUnknownMeshes[meshName] = true
			warn("Nuevo mesh detectado sin estilo: " .. meshName)
		end
	end
end

-- Process existing parts
for _, descendant in ipairs(workspace:GetDescendants()) do
	task.spawn(function()
		applyStyle(descendant)
	end)
end

-- Listen for new parts
workspace.DescendantAdded:Connect(function(descendant)
	task.spawn(function()
		applyStyle(descendant)
	end)
end)

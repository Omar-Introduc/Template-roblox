--!strict
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local RequestPointsEvent = Events:WaitForChild("RequestPlatformPoints") :: RemoteEvent

local function updatePlatform(platform: Instance)
	local mainPart = platform:IsA("Model") and platform.PrimaryPart or platform
	if not mainPart or not mainPart:IsA("BasePart") then return end

	-- Check if movement is active
	if not platform:GetAttribute("MovementActive") then return end

	local startTime = platform:GetAttribute("MovementStartTime")
	local originX = platform:GetAttribute("MovementOriginX")
	local originY = platform:GetAttribute("MovementOriginY")
	local centerZ = platform:GetAttribute("MovementCenterZ")
	local amplitude = platform:GetAttribute("MovementAmplitude")
	local speed = platform:GetAttribute("MovementSpeed")

	if not (startTime and originX and originY and centerZ and amplitude and speed) then return end

	local timeElapsed = os.clock() - startTime
	local newZ = centerZ + (math.sin(timeElapsed * speed) * amplitude)

	-- Smoothly update CFrame locally
	-- We preserve the rotation
	local currentCFrame = mainPart.CFrame
	local rotation = currentCFrame.Rotation
	mainPart.CFrame = CFrame.new(originX, originY, newZ) * rotation
end

-- Platform Movement Loop
RunService.Heartbeat:Connect(function()
	for _, platform in ipairs(CollectionService:GetTagged(GameConfig.TAG_PLATFORMA)) do
		updatePlatform(platform)
	end
end)

-- Standing Detection Loop
task.spawn(function()
	while true do
		task.wait(0.5)
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart
		local humanoid = character and character:FindFirstChild("Humanoid") :: Humanoid

		if character and rootPart and humanoid and humanoid.Health > 0 then
			local foundPlatform: Instance? = nil

			-- 1. Check Humanoid.FloorPart
			-- Wrap in pcall as FloorPart can be tricky or restricted sometimes
			local success, floor = pcall(function() return humanoid.FloorPart end)
			if success and floor then
				-- Find the model (Platform) from the part
				local model = floor:FindFirstAncestorWhichIsA("Model")
				if model and CollectionService:HasTag(model, GameConfig.TAG_PLATFORMA) then
					foundPlatform = model
				elseif floor and CollectionService:HasTag(floor, GameConfig.TAG_PLATFORMA) then
					foundPlatform = floor
				end
			end

			-- 2. Raycast fallback if no floor detected (e.g. slight jump or edge case)
			if not foundPlatform then
				local params = RaycastParams.new()
				params.FilterDescendantsInstances = {character}
				params.FilterType = Enum.RaycastFilterType.Exclude
				local res = workspace:Raycast(rootPart.Position, Vector3.new(0, -10, 0), params)

				if res and res.Instance then
					local hit = res.Instance
					local model = hit:FindFirstAncestorWhichIsA("Model")
					if model and CollectionService:HasTag(model, GameConfig.TAG_PLATFORMA) then
						foundPlatform = model
					elseif CollectionService:HasTag(hit, GameConfig.TAG_PLATFORMA) then
						foundPlatform = hit
					end
				end
			end

			if foundPlatform then
				RequestPointsEvent:FireServer(foundPlatform)
			end
		end
	end
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local HouseModules = require(Shared.HouseModules)

-- Define where to build the house
local HOUSE_ORIGIN = CFrame.new(0, 1, 0)

-- Build the house
print("Starting House Construction...")
local house = HouseModules.BuildHouse(HOUSE_ORIGIN)
print("House Built Successfully:", house:GetFullName())

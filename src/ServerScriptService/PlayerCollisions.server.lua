-- Used to keep players on the cart
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local function charaterAdded(character)
	local forceField = Instance.new("ForceField")
	forceField.Visible = false
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	humanoidRootPart.CanCollide = true
	forceField.Parent = character
	PhysicsService:SetPartCollisionGroup(humanoidRootPart, "Players")
end

local function playerAdded(player)
	player.CharacterAdded:Connect(charaterAdded)
end

Players.PlayerAdded:Connect(playerAdded)

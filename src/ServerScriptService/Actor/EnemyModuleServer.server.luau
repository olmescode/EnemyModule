local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local EnemyModule = require(ReplicatedStorage.EnemyModule)

local button = workspace.Button:FindFirstChild("On/OffButton")

local offColor = button.Color
local onColor = Color3.new(0.7, 0.2, 0.4)

local lastPressTime = tick()
local buttonActivated = false
local connection = nil

local SPAWN_OFFSET = Vector3.new(0, 6, 0)

local enemies = {}

local function spawnEnemy(enemySpawn)
	if enemySpawn then
		local enemyName = enemySpawn.EnemyName.Value
		local spawnLocation = enemySpawn.CFrame + SPAWN_OFFSET
		local enemyRespawn = enemySpawn.Respawn.Value
		local animations = enemySpawn.Animations:GetChildren()

		local enemy = EnemyModule.createEnemy(enemyName, spawnLocation, animations, enemyRespawn)
		enemy:start()
		--enemy:stop()

		table.insert(enemies, enemy)
	else
		warn("One or more of the arguments to spawnEnemy are nil")
	end
end

local function spawnEnemies()
	local enemySpawners = CollectionService:GetTagged("EnemySpawn")
	for _, enemySpawn in pairs(enemySpawners) do
		spawnEnemy(enemySpawn)
	end
end

local function cleanUpEnemies()
	for _, enemy in ipairs(enemies) do
		enemy:destroy()
	end
	enemies = {}
end

local function toggleButtonColor()
	if buttonActivated then
		button.Color = onColor
	else
		button.Color = offColor
	end
end

local function onCharacterTouch()
	if buttonActivated then
		-- Clean up enemies and resources
		cleanUpEnemies()
		buttonActivated = false
	else
		-- Spawn enemies
		spawnEnemies()
		buttonActivated = true
	end

	toggleButtonColor()
end

-- Connect button press event
local connection = button.Touched:Connect(function(otherPart)
	local ancestor = otherPart:FindFirstAncestorOfClass("Model")
	local player = Players:GetPlayerFromCharacter(ancestor)
	if player then
		local now = tick()
		if now - lastPressTime < 1 then
			return
		end

		lastPressTime = now
		onCharacterTouch()
	end
end)

-- Connect event for enemy death
EnemyModule.onEnemyDied:Connect(function(enemyName, hittingTarget)
	print("Enemy died:", enemyName, hittingTarget)
end)

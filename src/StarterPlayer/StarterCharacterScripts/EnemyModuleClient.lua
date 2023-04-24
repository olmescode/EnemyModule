local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local EnemyModule = require(ReplicatedStorage:WaitForChild("EnemyModule"))

local enemySpawners = CollectionService:GetTagged("EnemySpawn")
local trackNode = CollectionService:GetTagged("TrackNode")

local spawnerTable = {}

for _, spawner in ipairs(enemySpawners) do
	spawnerTable[spawner.Name] = spawner
end

local debounce = true
local collisionBoxPart = workspace.Enviroment.PartCollisionBox
local connection = nil

local SPAWN_OFFSET = Vector3.new(0, 6, 0)

local function tweenCameraToEnemy(target, enemy)
	local player = game.Players.LocalPlayer
	local camera = workspace.CurrentCamera

	-- Calculate the position to tween to
	local position = enemy.PrimaryPart.CFrame.Position - (camera.CFrame.LookVector * 15)

	-- Tween the camera to the new position and look at the enemy
	local tweenInfo = TweenInfo.new(5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local cameraTween = TweenService:Create(camera, tweenInfo, {
		CFrame = CFrame.new(position, enemy.PrimaryPart.CFrame.Position),
	})
	
	cameraTween:Play()
	cameraTween.Completed:Wait()
	cameraTween:Destroy()
end

local function spawnEnemy(otherPart)
	if spawnerTable then
		local trackNode = EnemyModule.createTrack(trackNode)
		local spawnLocation = spawnerTable.Spawner.CFrame + SPAWN_OFFSET
		local enemyType = spawnerTable.Spawner.EnemyType.Value
		local enemyDifficulty = spawnerTable.Spawner.Difficulty.Value
		local target = otherPart.Parent
		local enemy = nil
		
		-- Phase 1
		enemy = EnemyModule.createEnemy(enemyType, spawnLocation, enemyDifficulty, trackNode, target)
		tweenCameraToEnemy(target, enemy._enemy)
		enemy:performEnemyAttack("Phase 1")
		enemy:_destroy()
		task.wait(6)
		
		-- Phase 2
		spawnLocation = spawnerTable.Spawner2.CFrame + SPAWN_OFFSET
		enemyType = spawnerTable.Spawner2.EnemyType.Value
		enemyDifficulty = spawnerTable.Spawner2.Difficulty.Value
		
		enemy = EnemyModule.createEnemy(enemyType, spawnLocation, enemyDifficulty, trackNode, target)
		enemy:performEnemyAttack("Phase 2")
		enemy:_destroy()
		task.wait(6)
		
		-- Phase 3
		spawnLocation = spawnerTable.Spawner3.CFrame + SPAWN_OFFSET
		enemyType = spawnerTable.Spawner3.EnemyType.Value
		enemyDifficulty = spawnerTable.Spawner3.Difficulty.Value

		enemy = EnemyModule.createEnemy(enemyType, spawnLocation, enemyDifficulty, trackNode, target)
		enemy:performEnemyAttack("Phase 3")
		enemy:_destroy()
		task.wait(6)
		
		-- Phase 4
		spawnLocation = spawnerTable.Spawner4.CFrame + SPAWN_OFFSET
		enemyType = spawnerTable.Spawner4.EnemyType.Value
		enemyDifficulty = spawnerTable.Spawner4.Difficulty.Value

		enemy = EnemyModule.createEnemy(enemyType, spawnLocation, enemyDifficulty, trackNode, target)
		enemy:performEnemyAttack("Phase 4")
		enemy:_destroy()
	else
		warn("Spawner Folder object not detected in workspace")
	end
end

EnemyModule.onTargetDied:Connect(function()
	return
end)

connection = collisionBoxPart.Touched:Connect(function(otherPart)
	if debounce then
		debounce = false
		spawnEnemy(otherPart)
	end

	connection:Disconnect()
end)

--[[
connection = collisionBoxPart.Touched:Connect(function(otherPart)
	if debounce then
		debounce = false
		for _, enemySpawn in pairs(enemySpawners) do
			spawnEnemy(enemySpawn, otherPart)
		end
	end
	
	connection:Disconnect()
end)
]]

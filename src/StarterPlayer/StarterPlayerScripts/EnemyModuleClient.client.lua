local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local EnemyModule = require(ReplicatedStorage:WaitForChild("EnemyModule"))

local enemySpawners = CollectionService:GetTagged("EnemySpawn")
local enemyTrack = CollectionService:GetTagged("EnemyTrack")

local spawnerTable = {}

for _, spawner in ipairs(enemySpawners) do
	spawnerTable[spawner.Name] = spawner
end

local debounce = true
local collisionBoxPart = workspace.Enviroment.PartCollisionBox

local SPAWN_OFFSET = Vector3.new(0, 6, 0)

local function tweenCameraToEnemy(target, enemy)
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

local enemyData = {
	[1] = {
		spawner = spawnerTable.Spawner,
		attackPhase = "Phase 1",
		waitTime = 6,
	},
	[2] = {
		spawner = spawnerTable.Spawner2,
		attackPhase = "Phase 2",
		waitTime = 6,
	},
	[3] = {
		spawner = spawnerTable.Spawner3,
		attackPhase = "Phase 3",
		waitTime = 6,
	},
	[4] = {
		spawner = spawnerTable.Spawner4,
		attackPhase = "Phase 4",
		waitTime = 6,
	},
}

local function spawnEnemy(otherPart)
	if not spawnerTable then
		warn("Spawner Folder object not detected in workspace")
		return
	end
	local trackNode = EnemyModule.createTrack(enemyTrack)
	local target = otherPart.Parent
	local targetDied = false
	
	EnemyModule.onTargetDied:Connect(function()
		targetDied = true
	end)
	
	for index = 1, #enemyData do
		if targetDied then return end
		
		local data = enemyData[index]
		local spawner = data.spawner
		local attackPhase = data.attackPhase
		local waitTime = data.waitTime

		local spawnLocation = spawner.CFrame + SPAWN_OFFSET
		local enemyType = spawner.EnemyType.Value
		local enemyDifficulty = spawner.Difficulty.Value

		local enemy = EnemyModule.createEnemy(enemyType, spawnLocation, enemyDifficulty, trackNode, target)
		enemy:performEnemyAttack(attackPhase)
		enemy:_destroy()
		
		task.wait(waitTime)
	end
end

collisionBoxPart.Touched:Connect(function(otherPart)
	local player = Players:GetPlayerFromCharacter(otherPart.Parent)
	if player == Players.LocalPlayer and debounce then
		debounce = false
		spawnEnemy(otherPart)
	end
end)

local function onPlayerRespawn(character)
	debounce = true
end

Players.LocalPlayer.CharacterAdded:Connect(onPlayerRespawn)

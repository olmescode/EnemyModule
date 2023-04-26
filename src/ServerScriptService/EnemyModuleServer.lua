local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyModule = require(ReplicatedStorage:WaitForChild("EnemyModule"))

local enemySpawners = CollectionService:GetTagged("EnemySpawn")
local enemyTrack = CollectionService:GetTagged("EnemyTrack")

local debounce = true
local collisionBoxPart = workspace.Enviroment.PartCollisionBox
local connection = nil

local SPAWN_OFFSET = Vector3.new(0, 6, 0)

local function spawnEnemy(enemySpawn, otherPart)
	if enemySpawn then
		local trackNode = EnemyModule.createTrack(enemyTrack)
		local spawnLocation = enemySpawn.CFrame + SPAWN_OFFSET
		local enemyType = enemySpawn.EnemyType.Value
		local enemyDifficulty = enemySpawn.Difficulty.Value
		local target = otherPart.Parent

		local enemy = EnemyModule.EnemyManager.new(enemyType, spawnLocation, enemyDifficulty, trackNode, target)
		enemy:start()
	else
		warn("Spawner object not detected in table")
	end
end

EnemyModule.onTargetDied:Connect(function()
	return
end)

connection = collisionBoxPart.Touched:Connect(function(otherPart)
	if debounce then
		debounce = false
		for _, enemySpawn in pairs(enemySpawners) do
			spawnEnemy(enemySpawn, otherPart)
		end
	end

	connection:Disconnect()
end)

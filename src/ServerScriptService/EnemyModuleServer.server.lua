local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EnemyModule = require(ServerStorage.EnemyModule)
local SpawnConfiguration = require(ServerStorage.Configurations.EnemySpawning)
local GameSettings = require(ServerStorage.Configurations.GameSettings)

local enemySpawners = CollectionService:GetTagged("Enemy Spawn")
local waypoints = CollectionService:GetTagged("Waypoints")

local spawnPart = workspace.Part

local RandomGen = Random.new()

local SPAWN_OFFSET = Vector3.new(0, 6, 0)

local function spawnEnemy(enemySpawn)
	if enemySpawn then
		local path = EnemyModule.createPath(waypoints)

		local spawnLocation = enemySpawn.CFrame + SPAWN_OFFSET
		local enemyType = enemySpawn.EnemyType.Value

		local enemy = EnemyModule.EnemyManager.new(enemyType, spawnLocation, path, enemySpawn.difficulty.Value)
		enemy:spawnAgent()
		enemy:followPath()
		enemy:start()
	else
		warn("Spawner object not detected in table. Check that EnemySpawning > waypoints[] includes all spawners in the EnemySpawners folder")
	end
end

spawnPart.Touched:Connect(function()
	for _, enemySpawn in pairs(enemySpawners) do
		spawnEnemy(enemySpawn)
	end
end)

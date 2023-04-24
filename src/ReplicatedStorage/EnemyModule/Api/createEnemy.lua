local EnemyManager = require(script.Parent.Parent.Modules.EnemyManager)

return function(enemyType, spawnLocation, enemyDifficulty, trackNode, target)
	return EnemyManager.new(enemyType, spawnLocation, enemyDifficulty, trackNode, target)
end

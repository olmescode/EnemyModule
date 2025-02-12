local EnemyManager = require(script.Parent.Parent.Modules.EnemyManager)

return function(enemyName, enemySpawn, animations, enemyRespawn)
	return EnemyManager.new(enemyName, enemySpawn, animations, enemyRespawn)
end

print("Required EnemyModule")

local events = require(script.events)

local EnemyModule = {
	-- Configurations
	
	-- Server and client APIs
	createEnemy = require(script.Api.createEnemy),
	createTrack = require(script.Api.createTrack),
	
	-- Events
	onEnemyDied = events.enemyDied.Event,
	
	-- Remotes
	remotes = script.Remotes
}

return EnemyModule

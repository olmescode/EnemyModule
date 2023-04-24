print("Required EnemyModule")

local EnemyModule = {
	EnemyManager = require(script.Modules.EnemyManager),
	createEnemy = require(script.Api.createEnemy),
	createTrack = require(script.Api.createTrack),
	
	-- Events
	onTargetDied = script.Events.TargetDied.Event
}

return EnemyModule

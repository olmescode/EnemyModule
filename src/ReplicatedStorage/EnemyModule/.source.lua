print("Required EnemyModule")

local EnemyModule = {
	EnemyManager = require(script.Modules.EnemyManager),
	createTrack = require(script.Api.createTrack),
	createOrderedTrack = require(script.Api.createOrderedTrack)
}

return EnemyModule

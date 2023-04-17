print("Required EnemyModule")
local enemiesFolder = script.Enemies

local EnemyModule = {
	AgentManager = require(script.Modules.AgentManager),
	createTrack = require(script.Api.createTrack),
	enemiesFolder = enemiesFolder
}

return EnemyModule

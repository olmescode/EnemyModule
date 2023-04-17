print("Required EnemyModule")
local enemiesFolder = script.Enemies

local EnemyModule = {
	AgentManager = require(script.Modules.AgentManager),
	createPath = require(script.Api.createPath),
	enemiesFolder = enemiesFolder
}


local function spawnEnemies()
	local path = createPath()
	local GhostAgent = createAgent("Ghost", abilities.default)
	
	local ghostAgent = AgentManager.new(GhostAgent, path)
	ghostAgent:spawnAgent()
	ghostAgent:followPath()
end

function BasicAgents.Init()
	spawnEnemies()
end

return EnemyModule

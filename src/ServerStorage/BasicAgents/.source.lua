print("Required BasicAgentsServer")
local AgentManager = require(script.Modules.AgentManager)
local createAgent = require(script.Api.createAgent)
local createPath = require(script.Api.createPath)
local abilities = require(script.Components.Abilities)

local BasicAgents = {}

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
return BasicAgents

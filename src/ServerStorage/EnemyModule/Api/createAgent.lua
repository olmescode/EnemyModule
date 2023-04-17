local BasicAgents = script:FindFirstAncestor("BasicAgents")
local abilities = require(BasicAgents.Components.Abilities)
local enemiesFolder = BasicAgents.Components.Agents

local function createAgents(agent, ability)	
	local agent = enemiesFolder:FindFirstChild(agent)
	
	if not agent then
		warn("Not a valid enemy or not enemy found!")
		return false
	end
	agent = agent:Clone()
	if ability then
		for index, value in pairs(ability) do
			agent:SetAttribute(index, value)
		end
	else
		for index, value in pairs(abilities.default) do
			agent:SetAttribute(index, value)
		end
	end
	
	return agent
end

return createAgents

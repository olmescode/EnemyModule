local BasicAgents = script:FindFirstAncestor("BasicAgents")
local pathFolder = BasicAgents.Components.DefaultPath

local function createPath()
	local defaultPath = pathFolder:Clone()
	defaultPath.Parent = workspace
	
	local agentPath = {}
	
	for _, value in ipairs(defaultPath:GetChildren()) do
		table.insert(agentPath, value.Position)
	end
	
	return agentPath
end

return createPath

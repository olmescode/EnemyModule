local function createPath(waypoints)	
	local agentPath = {}
	for _, value in ipairs(waypoints:GetChildren()) do
		table.insert(agentPath, value.Position)
	end
	
	return agentPath
end

return createPath

local EnemyModule = script:FindFirstAncestor("EnemyModule")
local OrederedTrackNode = require(EnemyModule.Configurations.OrederedTrackNode)

local function createOrderedTrack(trackNode)
	local newTrackNode = {}
	for _, value in ipairs(trackNode) do
		newTrackNode[value.Name] = value.Position
	end
	
	local enemyTrack = {}
	for index, value in ipairs(OrederedTrackNode) do
		enemyTrack[index] = newTrackNode[value]
	end

	return enemyTrack
end

return createOrderedTrack

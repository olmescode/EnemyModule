local function createTrack(enemyTrack)
	local trackNode = {}
	for _, value in ipairs(enemyTrack) do
		table.insert(trackNode, value.Position)
	end
	
	return trackNode
end

return createTrack

local function createTrack(trackNode)
	local enemyTrack = {}
	for _, value in ipairs(trackNode) do
		table.insert(enemyTrack, value.Position)
	end
	
	return enemyTrack
end

return createTrack

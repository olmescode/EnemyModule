local EnemySettings = {}

-- Fields that define properties of the enemy
EnemySettings.EnemyData = {
	AgentRadius = 5,
	AgentHeight = 10,
	AgentCanJump = true,
	AgentCanClimb = true,
	WaypointSpacing	 = 4,
	Costs = {
		Water = 20
	}
}

-- Respaw time for enemies and boss
EnemySettings.RespawnTime = {
	Enemy = 20,
	Boss = 1800
}

return EnemySettings

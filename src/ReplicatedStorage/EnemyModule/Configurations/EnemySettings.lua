local EnemySettings = {}

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

-- Hitpoints for each enemy; one blaster shot takes 35 hitpoints
EnemySettings.HealthDifficulty = {
	Easy = 100,
	Normal = 125,
	Hard = 160
}

EnemySettings.attackPhase= {
	["Phase 1"] = {
		attackDamage = 100,
		attackInterval = 1,
		numberOfAttaks = 3,
		attackDuration = 10 -- assuming projectile speed is 10 units per second
	},
	["Phase 2"] = {
		attackDamage = 90,
		attackInterval = 0.7,
		numberOfAttaks = 4,
		attackDuration = 20
	},
	["Phase 3"] = {
		attackDamage = 80,
		attackInterval = 0.4,
		numberOfAttaks = 6,
		attackDuration = 30
	}
}

EnemySettings.FollowOrderedPath = true

return EnemySettings

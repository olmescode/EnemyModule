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

-- Defines the health values for enemies at different difficulty levels
EnemySettings.HealthDifficulty = {
	Easy = 100,
	Normal = 125,
	Hard = 160
}

-- Defines the properties of each attack phase for the enemy
EnemySettings.attackPhase= {
	["Phase 1"] = {
		attackDamage = 100, -- damage dealt
		attackInterval = 1, -- interval between attacks
		numberOfAttaks = 5, -- number of attacks
		attackDuration = 10 -- duration of the attack assuming projectile speed is 10 units per second
	},
	["Phase 2"] = {
		attackDamage = 100,
		attackInterval = 0.8,
		numberOfAttaks = 6,
		attackDuration = 13
	},
	["Phase 3"] = {
		attackDamage = 100,
		attackInterval = 0.6,
		numberOfAttaks = 7,
		attackDuration = 17
	},
	["Phase 4"] = {
		attackDamage = 100,
		attackInterval = 0.4,
		numberOfAttaks = 8,
		attackDuration = 25
	}
}

return EnemySettings

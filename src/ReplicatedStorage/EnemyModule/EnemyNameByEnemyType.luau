--!strict

--[[
	A mapping of BossEnemyTypes to EnemyNames used for defining enemy types 
	for different scenarios.
--]]

local EnemyModule = script:FindFirstAncestor("EnemyModule")

local EnemyNames = require(EnemyModule.EnemyNames)
local EnemyTypes = require(EnemyModule.EnemyTypes)

local EnemyNameByEnemyType: { [EnemyNames.EnumType]: EnemyTypes.EnumType } = {
	[EnemyNames.SteelTrainingDummy] = EnemyTypes.Enemy,
	[EnemyNames.Criminal] = EnemyTypes.Boss
	-- Add more mappings here as needed
}

return EnemyNameByEnemyType

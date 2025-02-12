--!strict

--[[
    Pseudo enums used to define Boss and Enemy types.
    This helps to avoid typos and improves code readability.
--]]

export type EnumType =
	"Boss"
	 | "Enemy"

local EnemyTypes = {
	Boss = "Boss" :: "Boss",
	Enemy = "Enemy" :: "Enemy"
}

return EnemyTypes

--!strict

--[[
    Pseudo enums used to define enemy types.
    This helps to avoid typos and improves code readability.
--]]

export type EnumType =
	"SteelTrainingDummy"
	 | "Criminal"

local EnemyNames = {
	SteelTrainingDummy = "SteelTrainingDummy" :: "SteelTrainingDummy",
	Criminal = "Criminal" :: "Criminal"
}

return EnemyNames

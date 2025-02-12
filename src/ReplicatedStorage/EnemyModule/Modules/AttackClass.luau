--!strict

local AttackClass = {}
AttackClass.__index = AttackClass

export type ClassType = typeof(setmetatable(
	{} :: {
		property: number,
	},
	AttackClass
	))

function AttackClass.new(property: number): ClassType
	local self = {
		property = property,
	}

	setmetatable(self, AttackClass)

	return self
end

function AttackClass.attackTarget(self: ClassType)
	self.property += 1
end

return AttackClass

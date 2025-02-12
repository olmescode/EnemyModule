local EnemyModule = script:FindFirstAncestor("EnemyModule")

local DamageBillboardHandler = require(EnemyModule.Components.DamageBillboardHandler)

local ToolAttackClass = {}
ToolAttackClass.__index = ToolAttackClass

function ToolAttackClass.new(tool)
	local self = setmetatable({}, ToolAttackClass)
	
	self._tool = tool
	self.handle = self._tool.Handle
	
	self.slashAnimation = self.handle.AnimationR15
	self.sound = self.handle.Sound

	-- Connect the Touched event of the ball to a function that handles what happens when the ball hits something
	self.touchedConnection = self.handle.Touched:Connect(function(otherPart) 
		self:_onTouch(otherPart)
	end)
	
	self.animationTrack = nil
	self.debounce = nil
	self.activated = nil
	self.DAMAGE_AMOUNT = 5
	
	return self
end

function ToolAttackClass:loadAnimationTrack()
	local character = self._tool.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			self.animationTrack = animator:LoadAnimation(self.slashAnimation)
		end
	end
end

function ToolAttackClass:handleDamage(humanoid)
	-- Apply damage
	humanoid:TakeDamage(self.DAMAGE_AMOUNT)
end

function ToolAttackClass:_onTouch(partOther)
	if self.debounce then
		-- First, try to see if the part we touched was part of a Humanoid
		local characOther = partOther.Parent :: Model
		local humanOther = partOther.Parent:FindFirstChild("Humanoid") :: Humanoid
		
		-- Ignore touches by non-humanoids
		if not humanOther then
			return
		end

		-- Ignore touches by the Humanoid carrying the sword
		if humanOther.Parent == self._tool.Parent then
			return
		end

		-- Trigger server-side damage handling
		self:handleDamage(humanOther)
		
		DamageBillboardHandler:showDamageBillboard(self.DAMAGE_AMOUNT, characOther:FindFirstChild("Head"))
		
		self.debounce = false
	end
end

function ToolAttackClass:attackTarget()
	if self.activated then return end
	self.activated = true
	
	
	self:loadAnimationTrack()

	if self.animationTrack then
		self.animationTrack:Play()
		self.sound:Play()

		self.debounce = true

		self.animationTrack.Ended:Connect(function()
			self.animationTrack:Destroy()
			self.activated = false
		end)
	end
end

-- Cleaner function
function ToolAttackClass:destroy()
	-- Disconnect event connections
	if self.touchedConnection then
		self.touchedConnection:Disconnect()
		self.touchedConnection = nil
	end
	
	-- Reset variables
	self._tool:Destroy()
	self._tool = nil
	self.handle = nil
	self.slashAnimation = nil
	self.sound = nil
	
	self.animationTrack = nil
	self.debounce = nil
	self.activated = nil
	self.DAMAGE_AMOUNT = nil
end

return ToolAttackClass

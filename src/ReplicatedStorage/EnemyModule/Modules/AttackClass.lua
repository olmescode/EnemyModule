local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local EnemyModule = script:FindFirstAncestor("EnemyModule")
local AttacksFolder = EnemyModule.Components

local attacks = {}
for _, child in ipairs(AttacksFolder:GetChildren()) do
	attacks[child.Name] = child
end

local AttackClass = {}
AttackClass.__index = AttackClass

function AttackClass.new(enemy, target, attackPhase)
	local self = setmetatable({}, AttackClass)
	
	self._attack = attacks["Projectile"]:Clone()
	
	self.enemy = enemy
	self._attackPhase = attackPhase
	self.target = target
	
	self.sound = self._attack.Fired
	
	-- Connect the Touched event of the ball to a function that handles what happens when the ball hits something
	self.touchedConnection = self._attack.Touched:Connect(function(otherPart) 
		self:_onTouch(otherPart)
	end)
	
	return self
end

function AttackClass:performEnemyAttack()
	if not self.enemy or not self.target then
		return
	end	
	local enemyPosition = self.enemy.PrimaryPart.Position + Vector3.new(0, 2, 0)
	local targetPosition = self.target.PrimaryPart.Position
	local targetVelocity = self.target.PrimaryPart.AssemblyLinearVelocity
	local predictedPosition = targetPosition + targetVelocity * 2

	self._attack.Position = enemyPosition
	self._attack.Parent = workspace

	local distance = (predictedPosition - enemyPosition).magnitude
	local duration = distance / self._attackPhase.attackDuration

	-- Create a Tween to move the ball from the initial position to the final position
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(self._attack, tweenInfo, {CFrame = CFrame.new(predictedPosition)})
	tween:Play()

	-- Play the sound of the ball being fired
	self.sound:Play()
	
	delay(duration, function()
		self:_destroy()
	end)
end

function AttackClass:attackTarget()
	if not self.enemy or not self.target then
		return
	end
	local enemy = self.enemy.PrimaryPart.Position
	local target = self.target.PrimaryPart.Position
	
	local direction = target - enemy
	local duration = math.log(1.001 + direction.Magnitude * 0.01) * 1.5 -- increase duration by 50%
	
	target = self.target.PrimaryPart.Position + self.target.HumanoidRootPart.AssemblyLinearVelocity * duration
	direction = target - enemy
	
	local force = direction / duration + Vector3.new(0, game.Workspace.Gravity * duration * 0.5, 0)
	
	self._attack.Position = enemy
	self._attack.Parent = workspace
	
	self._attack:ApplyImpulse(force * self._attack.AssemblyMass)
	
	delay(duration, function()
		self:_destroy()
	end)
end

-- 
function AttackClass:_onTouch(otherPart)
	if otherPart and otherPart.Parent then
		if otherPart.Parent == self.target then
			local humanoid = otherPart.Parent:FindFirstChild("Humanoid")
			
			humanoid:TakeDamage(self._attackPhase.attackDamage)
			self:_destroy()
		end
	end
end

-- Cleaner function
function AttackClass:_destroy()
	self.enemy = nil
	self._attackPhase = nil
	self.target = nil
	
	if self.touchedConnection then
		self.touchedConnection:Disconnect()
		self.touchedConnection = nil
	end
	
	self.sound:Destroy()
	self._attack:Destroy()
end

return AttackClass

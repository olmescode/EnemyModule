local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local EnemyModule = script:FindFirstAncestor("EnemyModule")
local EnemySettings = require(EnemyModule.Configurations.EnemySettings)
local AttackClass = require(EnemyModule.Modules.AttackClass)

local EnemiesFolder = EnemyModule.Enemies
local Animations = EnemyModule.Animations

local enemies = {}
for _, child in ipairs(EnemiesFolder:GetChildren()) do
	enemies[child.Name] = child
end

local EnemyManager = {}
EnemyManager.__index = EnemyManager

function EnemyManager.new(enemyType, enemySpawn, enemyDifficulty, trackNode, target)
	assert(enemies[enemyType], "Invalid enemy type")
	
	local self = setmetatable({}, EnemyManager)

	self._enemy = enemies[enemyType]:Clone()
	
	self.humanoid = self._enemy.Humanoid
	self.animator = self.humanoid.Animator
	
	self.target = if target then target else nil
	self.active = false
	self.orderedPath = if EnemySettings.FollowOrderedPath then EnemySettings.FollowOrderedPath else false
	self.currentPath = 0
	
	-- Disable unnecessary behaviors of humanoid to make game more efficient
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)

	-- Set enemy health based on difficulty
	self.humanoid.MaxHealth = EnemySettings.HealthDifficulty[enemyDifficulty]
	self.humanoid.Health = EnemySettings.HealthDifficulty[enemyDifficulty]

	self.humanoidDiedConnection = self.humanoid.Died:Connect(function()
		self:_destroy()
	end)

	self.touchedConnection = self._enemy.HumanoidRootPart.Touched:Connect(function(otherPart) 
		self:_onTouch(otherPart)
	end)
	
	self.targetDiedConnection = self.target.Humanoid.Died:Connect(function()
		self:_destroy()
	end)
	
	self._attackPhase = EnemySettings.attackPhase
	self.location = enemySpawn
	self.trackNode = trackNode
	self.enemyPath = PathfindingService:CreatePath(EnemySettings.EnemyData)
	self.waypoints = {}
	
	self.nextWaypointIndex = nil
	self.reachedConnection = nil
	
	self:spawnEnemy()
	
	return self
end

function EnemyManager:performEnemyAttack(Phase)
	local attackPhase = self._attackPhase[Phase]
	local attackInterval = attackPhase.attackInterval
	local numberOfAttaks = attackPhase.numberOfAttaks
	
	for index = 1, numberOfAttaks do
		if not self._enemy or not self.target then return end

		-- Look at the target
		local rootPart = self._enemy.PrimaryPart
		local upVector = Vector3.new(0, 1, 0)
		rootPart.CFrame = CFrame.lookAt(rootPart.Position, self.target.PrimaryPart.Position, Vector3.new(0, 1, 0))

		-- Attack the target
		local attackInstance = AttackClass.new(self._enemy, self.target, attackPhase)
		attackInstance:performEnemyAttack()
		task.wait(attackInterval)
	end
end

function EnemyManager:attackTarget()
	local maxHealth = self.humanoid.MaxHealth
	local currentHealth = self.humanoid.Health
	local attackPhase = nil
	local attackInterval = nil
	local numberOfAttaks = nil

	-- Calculate the percentage of remaining health
	local healthPercentage = currentHealth / maxHealth
	
	if healthPercentage > 0.5 then
		attackPhase = self._attackPhase["Phase 1"]
		attackInterval = self._attackPhase["Phase 1"].attackInterval
		numberOfAttaks = self._attackPhase["Phase 1"].numberOfAttaks
	elseif healthPercentage > 0.2 then
		attackPhase = self._attackPhase["Phase 2"].attackDamage
		attackInterval = self._attackPhase["Phase 2"].attackInterval
		numberOfAttaks = self._attackPhase["Phase 2"].numberOfAttaks
	else
		attackPhase = self._attackPhase["Phase 3"].attackDamage
		attackInterval = self._attackPhase["Phase 3"].attackInterval
		numberOfAttaks = self._attackPhase["Phase 3"].numberOfAttaks
	end
	
	for index = 1, numberOfAttaks do
		if not self._enemy or not self.target then return end
		
		-- Look at the target
		local rootPart = self._enemy.PrimaryPart
		local upVector = Vector3.new(0, 1, 0)
		rootPart.CFrame = CFrame.lookAt(rootPart.Position, self.target.PrimaryPart.Position, Vector3.new(0, 1, 0))
		
		-- Attack the target
		local attackInstance = AttackClass.new(self._enemy, self.target, attackPhase)
		attackInstance:attackTarget()
		task.wait(attackInterval)
	end
end

function EnemyManager:damageTarget(otherPart)
	local humanoid = otherPart.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Reduce the player's health by a certain amount
		humanoid:TakeDamage(10)
	end
end

function EnemyManager:spawnEnemy()
	local destination = self.location
	
	if self._enemy:IsA("BasePart") or self._enemy:IsA("MeshPart") then
		self._enemy.CFrame.Position = destination
		self._enemy.CanCollide = false
	elseif self._enemy:IsA("Model") then
		if self._enemy.PrimaryPart then
			self._enemy.PrimaryPart.Position = destination.Position
			for _, child in ipairs(self._enemy:GetDescendants()) do
				if child:IsA("BasePart") then
					child.CanCollide = false
				end
			end
		else
			warn(string.format("The _enemy %s needs to have a PrimaryPart.", self._enemy.Name))
			return false
		end
	else
		warn(string.format("The _enemy %s needs to be a Model or BasePart.", self._enemy.Name))
		return false
	end
	
	self._enemy.Parent = workspace
	
	-- Load animations
	self.idleAnimation = self.animator:LoadAnimation(Animations.IdleAnim)
	self.runAnimation = self.animator:LoadAnimation(Animations.RunAnim)
	self.jumpAnimation = self.animator:LoadAnimation(Animations.JumpAnim)
	
	self.idleAnimation:Play()
end

function EnemyManager:followTarged()
	if not self._enemy or not self.target then return end
	
	local targetPosition = self.target.PrimaryPart.Position
	local targetVelocity = self.target.PrimaryPart.AssemblyLinearVelocity
	local predictedPosition = targetPosition + targetVelocity * 2
	
	local success, errorMessage = pcall(function()
		self.enemyPath:ComputeAsync(self._enemy.PrimaryPart.Position, predictedPosition)
	end)
	if success and self.enemyPath.Status == Enum.PathStatus.Success then
		-- Get the path waypoints
		self.waypoints = self.enemyPath:GetWaypoints()
		-- Initially move to second waypoint (first waypoint is path start; skip it)
		self.nextWaypointIndex = 2
		
		-- Detect when movement to next waypoint is complete
		self.reachedConnection = self.humanoid.MoveToFinished:Connect(function(reached)
			if reached and self.nextWaypointIndex < #self.waypoints then
				-- Increase waypoint index and move to next waypoint
				self.nextWaypointIndex += 1

				-- If humanoid needs to jump
				if self.waypoints[self.nextWaypointIndex].Action == Enum.PathWaypointAction.Jump then
					self.jumpAnimation:Play()
					self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					self.jumpAnimation:Stop()
				end

				self.humanoid:MoveTo(self.waypoints[self.nextWaypointIndex].Position)
			else
				self.runAnimation:Stop()
				self.idleAnimation:Play()
				
				self:performEnemyAttack("Phase 3")

				if self.reachedConnection then
					self.reachedConnection:Disconnect()
					self.reachedConnection = nil
				end

				self.idleAnimation:Stop()
				-- Call function to re-compute new path
				self:followTarged()
			end
		end)
		
		self.idleAnimation:Stop()
		self.runAnimation:Play()
		self.humanoid:MoveTo(self.waypoints[self.nextWaypointIndex].Position)
	else
		warn("Path not computed!", errorMessage)
		-- Calculate the position to move towards or face
		self.humanoid:MoveTo(self._enemy.PrimaryPart.Position - (self._enemy.PrimaryPart.CFrame.LookVector * 10))
		
		-- Call function to re-compute new path
		self:followTarged()
	end
end

function EnemyManager:start()
	self.active = true
	self:followTarged()
end

function EnemyManager:stop()
	self.active = false
	self.humanoid.WalkSpeed = 0
end

function EnemyManager:_destroy()
	self.humanoid = nil
	self.animator = nil
	
	self.target = nil
	self.active = nil
	self.orderedPath = nil
	self.currentPath = nil
	
	self._attackType = nil
	self.location = nil
	self.trackNode = nil
	self.enemyPath = nil
	self.waypoints = nil

	self.nextWaypointIndex = nil
	
	self.humanoidDiedConnection:Disconnect()
	self.touchedConnection:Disconnect()
	self.targetDiedConnection:Disconnect()
	
	self.humanoidDiedConnection = nil
	self.touchedConnection = nil
	self.targetDiedConnection = nil
	
	if self.reachedConnection then
		self.reachedConnection:Disconnect()
		self.reachedConnection = nil
	end
	
	self._enemy:Destroy()
end

function EnemyManager:_onTouch(otherPart)
	if self.active then
		--hitPlayerEvent:Fire()
		self:damageTarget(otherPart)
	end
end

return EnemyManager

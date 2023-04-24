local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
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

function EnemyManager.new(enemyType, enemySpawn, trackNode, difficulty, target)
	assert(enemies[enemyType], "Invalid enemy type")

	local self = setmetatable({}, EnemyManager)

	self._enemy = enemies[enemyType]:Clone()

	self.humanoid = self._enemy.Humanoid
	self.animator = self.humanoid.Animator

	-- Disable unnecessary behaviors of humanoid to make game more efficient
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)

	-- Set enemy health based on difficulty
	self.humanoid.MaxHealth = EnemySettings.HealthDifficulty[difficulty]
	self.humanoid.Health = EnemySettings.HealthDifficulty[difficulty]

	-- Tag the enemy's model
	CollectionService:AddTag(self._enemy, "Enemy")

	self.humanoid.Died:Connect(function()
		self:_destroy()
	end)

	self._enemy.HumanoidRootPart.Touched:Connect(function(otherPart) 
		self:_onTouch(otherPart)
	end)

	self.target = if target then target else nil
	self.active = false
	self.orderedPath = if EnemySettings.FollowOrderedPath then EnemySettings.FollowOrderedPath else false
	self.currentPath = 0

	self.location = enemySpawn
	self.trackNode = trackNode
	self.enemyPath = PathfindingService:CreatePath(EnemySettings.EnemyData)
	self.waypoints = {}

	self.nextWaypointIndex = nil
	self.blockedConnection = nil
	self.reachedConnection = nil

	self:spawnEnemy()

	return self
end

function EnemyManager:findTarget()
	local maxDistance = 40
	local nearestTarget

	for _, player in ipairs(Players:GetChildren()) do
		if player.Character and player.Character.Humanoid and player.Character.Humanoid.Health > 0 then
			local target = player.Character
			local distance = (self._enemy.PrimaryPart.Position - target.PrimaryPart.Position).Magnitude

			if distance < maxDistance then
				nearestTarget = target
			end
		end
	end

	return nearestTarget
end

function EnemyManager:damageTarget(otherPart)
	local humanoid = otherPart.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Reduce the player's health by a certain amount
		humanoid:TakeDamage(10)
	end
end

function EnemyManager:getDestination()
	local destination = self.trackNode
	
	if self.orderedPath then
		self.currentPath += 1
		if self.currentPath > #self.trackNode then
			self.currentPath = 0
		end
		
		return destination[self.currentPath]
	end
	
	return destination[math.random(1, #destination)]
end

function EnemyManager:spawnEnemy()
	local destination = self.location

	if self._enemy:IsA("BasePart") or self._enemy:IsA("MeshPart") then
		self._enemy.CFrame.Position = destination
		--self._enemy.CanCollide = false
	elseif self._enemy:IsA("Model") then
		if self._enemy.PrimaryPart then
			self._enemy.PrimaryPart.Position = destination.Position
			for _, child in ipairs(self._enemy:GetDescendants()) do
				if child:IsA("BasePart") then
					--child.CanCollide = false
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

	--self.idleAnimation:Play()
end

function EnemyManager:followTarged()
	local targetPosition = self.target.PrimaryPart.Position
	local targetVelocity = self.target.PrimaryPart.AssemblyLinearVelocity
	local predictedPosition = targetPosition + targetVelocity * 2
	
	local success, errorMessage = pcall(function()
		self.enemyPath:ComputeAsync(self._enemy.PrimaryPart.Position, predictedPosition)
	end)
	if success and self.enemyPath.Status == Enum.PathStatus.Success then
		-- Get the path waypoints
		self.waypoints = self.enemyPath:GetWaypoints()
		self.nextWaypointIndex = 2
		
		-- If humanoid needs to jump
		if self.waypoints[self.nextWaypointIndex].Action == Enum.PathWaypointAction.Jump then
			self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
		
		self.humanoid:MoveTo(self.waypoints[self.nextWaypointIndex].Position)
		
	else
		-- Call function to re-compute new path
		self:followTarged()
	end
end

function EnemyManager:followPath()
	local destination = self:getDestination()
	
	-- Compute the path
	local success, errorMessage = pcall(function()
		self.enemyPath:ComputeAsync(self._enemy.PrimaryPart.Position, destination)
	end)
	
	if success and self.enemyPath.Status == Enum.PathStatus.Success then
		-- Get the path waypoints
		self.waypoints = self.enemyPath:GetWaypoints()
		
		-- Detect if path becomes blocked
		self.blockedConnection = self.enemyPath.Blocked:Connect(function(blockedWaypointIndex)
			-- Check if the obstacle is further down the path
			if blockedWaypointIndex >= self.nextWaypointIndex then
				
				-- Stop detecting path blockage until path is re-computed
				self.blockedConnection:Disconnect()
				self.blockedConnection = nil
				
				-- Call function to re-compute new path
				self:followPath()
			end
		end)

		-- Detect when movement to next waypoint is complete
		self.reachedConnection = self._enemy.Humanoid.MoveToFinished:Connect(function(reached)
			if reached and self.nextWaypointIndex < #self.waypoints then
				-- Find a target every waypoint
				self.target = self:findTarget()

				if self.target then
					self:followTarged()
				end
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
				
				self.blockedConnection:Disconnect()
				self.reachedConnection:Disconnect()

				self.blockedConnection = nil
				self.reachedConnection = nil

				-- Calculate the position to move towards
				--self.humanoid:MoveTo(self._enemy.PrimaryPart.Position - (self._enemy.PrimaryPart.CFrame.LookVector * 10))

				-- Call function to re-compute new path
				self:followPath()
			end
		end)
		
		-- Initially move to second waypoint (first waypoint is path start; skip it)
		self.nextWaypointIndex = 2
		self.runAnimation:Play()
		self.humanoid:MoveTo(self.waypoints[self.nextWaypointIndex].Position)
	else
		warn("Path not computed!", errorMessage)
		-- Call function to re-compute new path
		self:followPath()
	end
end

function EnemyManager:start()
	self.active = true
	self:followPath()
end

function EnemyManager:stop()
	self.active = false
	self.humanoid.WalkSpeed = 0
end

function EnemyManager:_destroy()
	self._enemy:Destroy()
end

function EnemyManager:_onTouch(otherPart)
	if self.active then
		--hitPlayerEvent:Fire()
		self:damageTarget(otherPart)
	end
end

return EnemyManager

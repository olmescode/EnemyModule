local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")

local EnemyModule = script:FindFirstAncestor("EnemyModule")
local EnemiesFolder = EnemyModule.Enemies
local EnemySettings = require(script.Configurations.EnemySettings)

local enemies = {}
for _, child in ipairs(EnemiesFolder:GetChildren()) do
	enemies[child.Name] = child
end

local EnemyManager = {}
EnemyManager.__index = EnemyManager

function EnemyManager.new(enemyType, location, trackNode, difficulty, enemyRespawn)
	assert(enemies[enemyType], "Invalid enemy type")
	
	local self = setmetatable({}, EnemyManager)

	self._enemy = enemies[enemyType]:Clone()	

	-- Disable unnecessary behaviors of humanoid to make game more efficient
	--self._enemy.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	--self._enemy.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	--self._enemy.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)

	-- Set enemy health based on difficulty
	self._enemy.Humanoid.MaxHealth = EnemySettings.EnemyHealthDifficulty[difficulty]
	self._enemy.Humanoid.Health = EnemySettings.EnemyHealthDifficulty[difficulty]

	-- Tag the enemy's model
	CollectionService:AddTag(self._enemy, "Enemy")

	self._enemy.Humanoid.Died:Connect(function()
		self:_destroy()
	end)

	self._enemy.HumanoidRootPart.Touched:Connect(function(otherPart) 
		self:_onTouch(otherPart)
	end)

	self.target = nil
	self.respawn = if enemyRespawn then enemyRespawn else false
	self.active = false
	
	self.location = location
	self.trackNode = trackNode
	self.enemyPath = PathfindingService:CreatePath()
	self.waypoints = {}
	
	self.nextWaypointIndex = nil
	self.blockedConnection = nil
	self.reachedConnection = nil

	return self
end

function EnemyManager:findTarget()
	local maxDistance = 40
	local nearestTarget

	for _, player in ipairs(Players:GetChildren()) do
		if player.Character then
			local target = player.Character
			local distance = (self._enemy.PrimaryPart.Position - target.HumanoidRootPart.Position).Magnitude

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
		humanoid:TakeDamage(1)
	end
end

function EnemyManager:getDestination()
	local destination = self.trackNode
	return destination[math.random(1, #destination)]
end

function EnemyManager:spawnAgent()
	local destination = self.location or self:getDestination()
	
	if self._enemy:IsA("BasePart") or self._enemy:IsA("MeshPart") then
		self._enemy.CFrame.Position = destination
		--agent.CanCollide = false
	elseif self._enemy:IsA("Model") then
		if self._enemy.PrimaryPart then
			self._enemy.PrimaryPart.Position = destination
			for _, child in ipairs(self._enemy:GetDescendants()) do
				if child:IsA("BasePart") then
					--child.CanCollide = false
				end
			end
		else
			warn(string.format("The Model %s needs to have a PrimaryPart.", self._enemy.Name))
			return false
		end
	else
		warn(string.format("The agent %s needs to be a Model or BasePart.", self._enemy.Name))
		return false
	end
	
	self._enemy.PrimaryPart:SetNetworkOwner(nil)
	self._enemy.Parent = workspace
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
			-- Recompute the path
			self.enemyPath:ComputeAsync(self._enemy.PrimaryPart.Position, destination)
			
			-- Check if the obstacle is further down the path
			if blockedWaypointIndex >= self.nextWaypointIndex then
				-- Calculate the position to move towards
				self._enemy.Humanoid:MoveTo(self._enemy.PrimaryPart.CFrame - (self._enemy.PrimaryPart.CFrame.LookVector * 10))
				
				--make the model face the opposite direction
				self._enemy.Humanoid:LookAt(self._enemy.PrimaryPart.CFrame * -1)
				
				-- Stop detecting path blockage until path is re-computed
				self.blockedConnection:Disconnect()
				self.blockedConnection = nil
				
				-- Call function to re-compute new path
				self:followPath()
			end
		end)

		-- Detect when movement to next waypoint is complete
		if not self.reachedConnection then
			
			self.reachedConnection = self.humanoid.MoveToFinished:Connect(function(reached)
				if reached and self.nextWaypointIndex < #self.waypoints then
					-- Find a target every waypoint
					self.target = self:findTarget()
					
					if self.target then
						local targetPosition = self.target.PrimaryPart.Position
						local targetVelocity = self.target.PrimaryPart.AssemblyLinearVelocity
						local predictedPosition = targetPosition + targetVelocity * 4

						self.enemyPath:ComputeAsync(self._enemy.PrimaryPart.Position, predictedPosition)
						self.waypoints = self.enemyPath:GetWaypoints()
						self.nextWaypointIndex = 2
						
						self._enemy.Humanoid:MoveTo(self.waypoints[self.nextWaypointIndex].Position)
					end
					
					-- Increase waypoint index and move to next waypoint
					self.nextWaypointIndex += 1
					
					-- If humanoid needs to jump
					if self.waypoints[self.nextWaypointIndex].Action == Enum.PathWaypointAction.Jump then
						self._enemy.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					end
					
					self._enemy.Humanoid:MoveTo(self.waypoints[self.nextWaypointIndex].Position)
				else
					self.blockedConnection:Disconnect()
					self.reachedConnection:Disconnect()
					
					self.blockedConnection = nil
					self.reachedConnection = nil
					self.nextWaypointIndex = 0
					
					-- Call function to re-compute new path
					self:followPath()
				end
			end)
		end
		
		-- Initially move to second waypoint (first waypoint is path start; skip it)
		self.nextWaypointIndex = 2
		self._enemy.Humanoid:MoveTo(self.waypoints[self.nextWaypointIndex].Position)
	else
		warn("Path not computed!", errorMessage)
		-- Call function to re-compute new path
		self:followPath()
	end
end

function EnemyManager:start()
	self.active = true
	self:spawnAgent()
	self.followPath()
end

function EnemyManager:stop()
	self.active = false
	self._enemy.Humanoid.WalkSpeed = 0
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

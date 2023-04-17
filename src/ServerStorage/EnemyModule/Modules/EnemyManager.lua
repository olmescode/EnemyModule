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

function EnemyManager.new(enemyType, location, path, difficulty)
	assert(enemies[enemyType], "Invalid enemy type")
	
	local self = setmetatable({}, EnemyManager)

	self._model = enemies[enemyType]:Clone()	

	-- Disable unnecessary behaviors of humanoid to make game more efficient
	--self._model.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	--self._model.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	--self._model.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)

	-- Set enemy health based on difficulty
	self._model.Humanoid.MaxHealth = EnemySettings.EnemyHealthDifficulty[difficulty]
	self._model.Humanoid.Health = EnemySettings.EnemyHealthDifficulty[difficulty]

	-- Tag the enemy's model
	CollectionService:AddTag(self._model, "Enemy")

	self._model.Humanoid.Died:Connect(function()
		self:_destroy()
	end)

	self._model.HumanoidRootPart.Touched:Connect(function(otherPart) 
		self:_onTouch(otherPart)
	end)

	self.target = nil
	self.active = false
	self.waypoints = path
	self.enemyPath = PathfindingService:CreatePath()

	self._model:SetPrimaryPartCFrame(location)
	self._model.Parent = game.Workspace.Targets

	return self

	local self = {
		enemy = enemies[enemyType]:Clone(),
		humanoid = enemy.Humanoid,
		--agentpath = path,
		--agentAbility = agent:GetAttributes(),
		--path = PathfindingService:CreatePath(agentAbility),
		waypoints = {},
		nextWaypointIndex = nil,
		blockedConnection = nil,
		reachedConnection = nil,
		enabled = true,
	}

	return self
end

function EnemyManager:findTarget()
	local maxDistance = 40
	local nearestTarget

	for _, player in ipairs(Players:GetChildren()) do
		if player.Character then
			local target = player.Character
			local distance = (self.agent.PrimaryPart.Position - target.HumanoidRootPart.Position).Magnitude

			if distance < maxDistance then
				nearestTarget = target
				maxDistance = distance
			end
		end
	end

	return nearestTarget
end

function EnemyManager:damageTarget(target)
	local distance = (self.agent.PrimaryPart.Position - target.HumanoidRootPart.Position).Magnitude

	if distance < 8 then
		target.Humanoid.Health -= 1
	end
end

function EnemyManager:getDestination()
	local destination = self.agentpath
	return destination[math.random(1, #destination)]
end

function EnemyManager:spawnAgent()
	local destination = self:getDestination()
	
	if self.agent:IsA("BasePart") or self.agent:IsA("MeshPart") then
		self.agent.CFrame.Position = destination
		--agent.CanCollide = false
	elseif self.agent:IsA("Model") then
		if self.agent.PrimaryPart then
			self.agent.PrimaryPart.Position = destination
			for _, child in ipairs(self.agent:GetDescendants()) do
				if child:IsA("BasePart") then
					--child.CanCollide = false
				end
			end
		else
			warn(string.format("The Model %s needs to have a PrimaryPart.", self.agent.Name))
			return false
		end
	else
		warn(string.format("The agent %s needs to be a Model or BasePart.", self.agent.Name))
		return false
	end
	
	self.agent.Parent = workspace
	self.agent.PrimaryPart:SetNetworkOwner(nil)
end

function EnemyManager:followPath()
	local destination = self:getDestination()
	
	-- Compute the path
	local success, errorMessage = pcall(function()
		self.path:ComputeAsync(self.agent.PrimaryPart.Position, destination)
	end)
	
	if success and self.path.Status == Enum.PathStatus.Success then
		-- Get the path waypoints
		self.waypoints = self.path:GetWaypoints()
		
		-- Detect if path becomes blocked
		self.blockedConnection = self.path.Blocked:Connect(function(blockedWaypointIndex)
			-- Check if the obstacle is further down the path
			if blockedWaypointIndex >= self.nextWaypointIndex then
				self.humanoid:MoveTo(destination - (self.agent.PrimaryPart.CFrame.LookVector * 10))
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
					local target = self:findTarget()
					
					-- Increase waypoint index and move to next waypoint
					self.nextWaypointIndex += 1
					
					-- If humanoid needs to jump
					if self.waypoints[self.nextWaypointIndex].Action == Enum.PathWaypointAction.Jump then
						self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					end
					
					self.humanoid:MoveTo(self.waypoints[self.nextWaypointIndex].Position)
					
					if target then
						self.humanoid:MoveTo(target.HumanoidRootPart.Position)
						self:damageTarget(target)
						
						self.path:ComputeAsync(self.agent.PrimaryPart.Position, target.HumanoidRootPart.Position)
						self.waypoints = self.path:GetWaypoints()
						self.nextWaypointIndex = 2
						self.humanoid:MoveTo(self.waypoints[self.nextWaypointIndex].Position)
						self:damageTarget(target)
					end
				else
					print(self.nextWaypointIndex .. " waypoints finished!")
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
		self.humanoid:MoveTo(self.waypoints[self.nextWaypointIndex].Position)
	else
		warn("Path not computed!", errorMessage)
		self.humanoid:MoveTo(destination - (self.agent.PrimaryPart.CFrame.LookVector * 10))
		-- Call function to re-compute new path
		self:followPath()
	end
end

----
function Enemy:_update()
	if self._model and self._model:FindFirstChild("Humanoid") then
		local targetPosition = self._target.PrimaryPart.Position
		local targetVelocity = self._target.PrimaryPart.AssemblyLinearVelocity
		local predictedPosition = targetPosition + targetVelocity * 4
		self._model.Humanoid:MoveTo(targetPosition)
	end
end

-- Main enemy loop
function Enemy:start()
	coroutine.wrap(function()
		self._active = true
		while(self._active) do
			self:_update()
			wait(UPDATE_TIME_INTERVAL)
		end
	end)()
end

function Enemy:stop()
	self._active = false
	self._model.Humanoid.WalkSpeed = 0
end

function Enemy:_destroy()
	self._model:Destroy()
end

function Enemy:_onTouch(otherPart)
	if self._active and CollectionService:HasTag(otherPart, "Platform") then
		hitPlatformEvent:Fire()
		self:stop()
		self:_destroy()
	end
end
----
return EnemyManager

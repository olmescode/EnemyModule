local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local EnemyModule = script:FindFirstAncestor("EnemyModule")

local t = require(EnemyModule.Packages.t)
local events = require(EnemyModule.events)
local EnemySettings = require(EnemyModule.EnemySettings)
local AttackClass = require(EnemyModule.Modules.AttackClass)
local ToolAttackClass = require(EnemyModule.Modules.ToolAttackClass)
local EnemyNameByEnemyType = require(EnemyModule.EnemyNameByEnemyType)

local EnemiesFolder = EnemyModule.Enemies
local DefaultAnimations = EnemyModule.DefaultAnimations
local HealthBarBillboard = EnemyModule.HealthBarBillboard

-- Attack configuration
local ATTACK_DAMAGE = 10
local ATTACK_RADIUS = 50
local ATTACK_RANGE = 7
local ATTACK_DELAY = 3
local DISTANCE_OFFSET = 7
local DETECTION_RANGE_RAY = 15

-- Patrol configuration
local PATROL_RADIUS = 20
local MIN_REPOSITION_TIME = 2
local MAX_REPOSITION_TIME = 6

-- Target configuration
local TARGET_CHECK_INTERVAL = 1

-- Health regeneration configuration
local REGENERATION_RATE = 1
local REGENERATION_INTERVAL = 1
local DEATH_DESTROY_DELAY = 3
local RESPAWN_TIME = 10

-- Teleport configuration
local TELEPORT_CHECK_INTERVAL = 5
local TELEPORT_DISTANCE_THRESHOLD = 300

local random = Random.new()
local smallButNotZero = 0.0001

local enemies = {}
for _, child in ipairs(EnemiesFolder:GetChildren()) do
	enemies[child.Name] = child
end

local EnemyManager = {}
EnemyManager.__index = EnemyManager

function EnemyManager.new(enemyName, enemySpawn, animations, enemyRespawn)
	assert(enemies[enemyName], "Bad argument #1 to EnemyModule.createEnemy: invalid enemy name")
	assert(t.CFrame(enemySpawn), "Bad argument #2 to EnemyModule.createEnemy: expected a CFrame")
	assert(t.table(animations), "Bad argument #3 to EnemyModule.createEnemy: expected a table")
	assert(t.boolean(enemyRespawn), "Bad argument #4 to EnemyModule.createEnemy: expected a boolean")

	local self = setmetatable({}, EnemyManager)

	self._enemyName = enemyName
	self._enemy = enemies[enemyName]:Clone()
	self._spawnLocation = enemySpawn
	self._respawnable = enemyRespawn
	self._animations = animations
	self._enemyDied = events.enemyDied
	self._respawnTime = EnemySettings.RespawnTime[EnemyNameByEnemyType[enemyName]] or RESPAWN_TIME
	
	self._active = true
	self._patrol = false
	
	local animations = {}
	for _, child in ipairs(self._animations) do
		animations[child.Name] = child
	end
	self._animations = animations
	
	self:_initialize()

	return self
end

function EnemyManager:_loadAnimation(animationName)
	local animation = self._animations[animationName] or DefaultAnimations:FindFirstChild(animationName)
	if animation then
		return self.animator:LoadAnimation(animation)
	end

	return nil
end

function EnemyManager:_initializeAnimations()
	-- Load necessary animations
	self.idleAnimation = self:_loadAnimation("IdleAnim")
	self.runAnimation = self:_loadAnimation("RunAnim")
	self.walkAnimation = self:_loadAnimation("WalkAnim")
	self.jumpAnimation = self:_loadAnimation("JumpAnim")

	self.hitAnimation = self:_loadAnimation("HitAnim")
	self.attackAnimation = self:_loadAnimation("AttackAnim")
	self.attackAnimation2 = self:_loadAnimation("AttackAnim2")
	self.attackAnimation3 = self:_loadAnimation("AttackAnim3")
	
	-- Collect valid attack animations
	if self.attackAnimation then table.insert(self.valitAttackAnimations, self.attackAnimation) end
	if self.attackAnimation2 then table.insert(self.valitAttackAnimations, self.attackAnimation2) end
	if self.attackAnimation3 then table.insert(self.valitAttackAnimations, self.attackAnimation3) end
end

function EnemyManager:_setNetworkOwnership()
	for _, part in ipairs(self._enemy:GetDescendants()) do
		if part:IsA("BasePart") then
			part:SetNetworkOwner(nil)
		end
	end
end

function EnemyManager:_initialize()
	self.humanoid = self._enemy.Humanoid
	self.animator = self.humanoid.Animator
	
	self._tool = self._enemy:FindFirstChildOfClass("Tool")
	if self._tool then
		self.toolInstance = ToolAttackClass.new(self._tool)
	end

	self.healthBarBillboard = HealthBarBillboard:Clone()
	self.healthBarBillboard.Adornee = self._enemy.Head
	self.healthBarBillboard.Parent = self._enemy

	self.target = nil
	self.hittingTarget = nil
	self.attacking = false
	self.inAttackRange = false
	
	self.valitAttackAnimations = {}
	
	-- Add AlignOrientation and Attachments
	self.worldAttachment = Instance.new("Attachment")
	self.worldAttachment.Parent = self._enemy.HumanoidRootPart

	self.alignOrientation = Instance.new("AlignOrientation")
	self.alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	self.alignOrientation.Enabled = false
	self.alignOrientation.Attachment0 = self.worldAttachment
	self.alignOrientation.AlignType = Enum.AlignType.PrimaryAxisParallel
	self.alignOrientation.RigidityEnabled = true
	self.alignOrientation.Parent = self._enemy.HumanoidRootPart
	
	-- Disable unnecessary behaviors of humanoid to make game more efficient
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)

	self.humanoidDiedConnection = self.humanoid.Died:Connect(function()
		-- TODO: Animate
		self._enemyDied:Fire(self._enemyName, self.hittingTarget)
		
		-- Clean up the current enemy instance
		task.delay(DEATH_DESTROY_DELAY, function()
			self:destroy()
			self:_respawn()
		end)
	end)

	self.humanoidHealthConnection = self.humanoid.HealthChanged:Connect(function()
		self:_updateHealthPercentage()
	end)
	
	-- 
	self.humanoidRunningConnection = self.humanoid.Running:Connect(function(speed)
		self:_handleRunning(speed)
	end)
	
	self.location = self._spawnLocation
	self.respawnable = self._respawnable
	
	self.respawnTask = nil
	
	self.currentAnim = nil
	self.currentAnimTrack = nil
	self.currentAnimSpeed = 1.0
	
	self.regenerationElapsedTime = 0
	self.targetCheckElapsedTime = 0
	self.teleportCheckElapsedTime = 0
	self.lastAttackTime = 0
	self.searchingForTargets = false
	
	self.heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
		self:_onHeartbeat(deltaTime)
	end)
	
	self:_spawnEnemy()
	self:_setNetworkOwnership()
	self:_initializeAnimations()
end

function EnemyManager:_setRunSpeed(speed)
	local heightScale = 1
	local runSpeed = speed * 1.25 / heightScale

	if runSpeed ~= self.currentAnimSpeed then
		self.currentAnimSpeed = runSpeed
		self.runAnimation:AdjustSpeed(runSpeed)
	end
end

function EnemyManager:_playRunAnimation()
	if self.currentAnim == "run" then
		return
	end

	self.idleAnimation:Stop(0.1)

	self.currentAnimTrack = self.runAnimation

	self.currentAnimTrack.Priority = Enum.AnimationPriority.Core
	self.currentAnimTrack:Play()

	self.currentAnim = "run"
	self.currentAnimSpeed = 1.0
end

function EnemyManager:_playIdleAnimation()
	if self.currentAnim == "idle" then
		return
	end

	if self.currentAnimTrack then
		self.currentAnimTrack:Stop(0.1)
	end

	self.currentAnimTrack = self.idleAnimation
	self.currentAnimTrack.Priority = Enum.AnimationPriority.Core
	self.currentAnimTrack:Play()

	self.currentAnim = "idle"
end

function EnemyManager:_handleRunning(speed)
	if speed > 0.75 then
		self:_playRunAnimation(speed)
		self:_setRunSpeed(speed / 16.0)
	else
		self:_playIdleAnimation(speed)
	end
end

function EnemyManager:_startHealthRegeneration(deltaTime)
	self.regenerationElapsedTime = self.regenerationElapsedTime + deltaTime
	if self.regenerationElapsedTime >= REGENERATION_INTERVAL then
		self.regenerationElapsedTime = 0
		if self.humanoid.Health > 0 and self.humanoid.Health < self.humanoid.MaxHealth then
			self.humanoid.Health = math.min(self.humanoid.Health + REGENERATION_RATE, self.humanoid.MaxHealth)
		end
	end
end

function EnemyManager:_updateHealthPercentage()
	local humanoid = self.humanoid
	
	local healthBarBillboard = self.healthBarBillboard
	local healthBar = healthBarBillboard.Container.HealthBar
	local progressBar = healthBar.ProgressBar
	local textLabel = healthBar.TextLabel
	
	-- Update the health percentage
	local healthPercentage = math.floor(humanoid.Health / humanoid.MaxHealth * 100)
	
	-- Calculate the new size of the progress bar based on the health percentage
	local newSize = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
	
	progressBar:TweenSize(
		UDim2.new(newSize, 0, 1, 0), -- endSize
		Enum.EasingDirection.Out, -- easingDirection
		Enum.EasingStyle.Quad, -- easingStyle
		0.5, -- time
		true -- override in-progress tweens
	)
	
	textLabel.Text = tostring(healthPercentage) .. "%"
end

function EnemyManager:_getRandomPointInCircle()
	-- PARALLEL: Simultaneous execution
	task.desynchronize()
	
	local radius = math.sqrt(random:NextNumber()) * PATROL_RADIUS
	local angle = random:NextNumber(0, math.pi * 2)
	local x = self.location.X + radius * math.cos(angle)
	local z = self.location.Z + radius * math.sin(angle)

	local position = Vector3.new(x, self.location.Y, z)
	
	-- SERIAL: Sequential execution
	task.synchronize()
	
	return position
end

function EnemyManager:_updateAlignOrientation()
	if not self._active then return end
	
	local target = self.hittingTarget or self.target
	if target then
		self.alignOrientation.Enabled = true
		self.alignOrientation.CFrame = CFrame.new(self._enemy.PrimaryPart.Position, target.PrimaryPart.Position)
	else
		self.alignOrientation.Enabled = false
	end
end

function EnemyManager:_findTarget()
	if self.searchingForTargets then return end
	
	self.searchingForTargets = true
	
	local nearestTarget = nil
	local newTargetDistance = nil
	
	if RunService:IsServer() then
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = {self._enemy}
		
		-- PARALLEL: Simultaneous execution
		task.desynchronize()
		
		local hitParts = workspace:GetPartBoundsInRadius(self._enemy.PrimaryPart.Position, ATTACK_RADIUS, overlapParams)
		local detectedTargets = {}
		
		for _, hitPart in ipairs(hitParts) do
			local characterMaybe = hitPart.Parent
			if characterMaybe and not detectedTargets[characterMaybe] then
				local humanoid = characterMaybe:FindFirstChildOfClass("Humanoid")
				local isEnemyFriend = characterMaybe:GetAttribute("EnemyFriend")
				if humanoid and not isEnemyFriend then
					local target = characterMaybe
					local distance = (self._enemy.PrimaryPart.Position - target.PrimaryPart.Position).Magnitude
					
					-- Determine if the charater is the closest
					if not newTargetDistance or distance < newTargetDistance then
						nearestTarget = target
						newTargetDistance = distance
					end
					
					detectedTargets[characterMaybe] = true
				end
			end
		end
		
		-- Clear the table after processing
		for npc, _ in pairs(detectedTargets) do
			detectedTargets[npc] = nil
		end
	else
		local target = Players.LocalPlayer.Character
		local distance = (self._enemy.PrimaryPart.Position - target.PrimaryPart.Position).Magnitude
		
		if distance < ATTACK_RADIUS then
			nearestTarget = target
		end
	end
	
	-- SERIAL: Sequential execution
	task.synchronize()
	
	self.searchingForTargets = false
	
	return nearestTarget
end

function EnemyManager:_attackTargetInRange()
	-- TODO: Improve attack actions and handle them in the cliend
	if #self.valitAttackAnimations == 0 then
		return
	end

	local attackAnimation = self.valitAttackAnimations[math.random(#self.valitAttackAnimations)]

	if attackAnimation then
		attackAnimation:Play()
	end
	
	local humanoidRootPart = self._enemy:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {self._enemy}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	-- Concurrent execution across multiple threads
	task.desynchronize()
	
	local target = self.hittingTarget or self.target
	local direction = (target.PrimaryPart.Position - humanoidRootPart.Position).Unit * DETECTION_RANGE_RAY
	local raycastResult = workspace:Raycast(humanoidRootPart.Position, direction, raycastParams)

	-- Sequential execution, affecting shared state
	task.synchronize()

	if raycastResult then
		local hitPart = raycastResult.Instance
		local otherHumanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid")

		if otherHumanoid then
			local isBlocking = otherHumanoid.Parent:GetAttribute("Blocking")
			local isEnemyFriend = otherHumanoid.Parent:GetAttribute("EnemyFriend")
			if not isBlocking and not isEnemyFriend then
				self:_damageTarget(otherHumanoid)
			else
				-- Handle case where player is blocking
			end
		end
	end
end

function EnemyManager:_attackTarget()
	local currentTime = tick()
	self.attacking = true
	
	if currentTime - self.lastAttackTime > ATTACK_DELAY then
		-- Use enemie's tool to attack the player
		if self._tool then
			self.toolInstance:attackTarget()
		end
		
		self:_attackTargetInRange()
		
		self.lastAttackTime = currentTime
		self.attacking = false
	end
end

function EnemyManager:_damageTarget(otherHumanoid)
	otherHumanoid:TakeDamage(ATTACK_DAMAGE)
end

function EnemyManager:_spawnEnemy()
	self._enemy:PivotTo(self.location)
	self._enemy.Parent = workspace
end

function EnemyManager:_cloneNewEnemy()
	return enemies[self._enemyName]:Clone()
end

function EnemyManager:_respawn()
	if not self.respawnable then
		return
	end
	
	-- Clone a new enemy instance
	self._enemy = self:_cloneNewEnemy()
	
	-- Schedule a new task for respawn
	self.respawnTask = task.delay(self._respawnTime, function()
		self:_initialize()

		if self._patrol then
			self:start()
		end

		if not self._active then
			self:stop()
		end
		
		-- Remove the task reference
		self.respawnTask = nil
	end)
end

function EnemyManager:_handleHitEffects()
	if self.hitAnimation then
		self.hitAnimation:Play()
	end
end

function EnemyManager:_checkRecentlyHit()
	local playerName = self._enemy:GetAttribute("RecentlyHit")
	if playerName then
		self:_handleHitEffects()
		self._enemy:SetAttribute("RecentlyHit", nil)

		-- Find the player by name
		local player = Players:FindFirstChild(playerName)
		if player and player.Character then
			self.hittingTarget = player.Character
		end
	end
end

function EnemyManager:_moveToSpawnLocation()
	self.humanoid:MoveTo(self.location.Position)
end

function EnemyManager:_checkDistanceFromSpawn(deltaTime)
	self.teleportCheckElapsedTime = self.teleportCheckElapsedTime + deltaTime
	if self.teleportCheckElapsedTime >= TELEPORT_CHECK_INTERVAL then
		self.teleportCheckElapsedTime = 0
		local currentDistance = (self._enemy.HumanoidRootPart.Position - self.location.Position).Magnitude
		if currentDistance > TELEPORT_DISTANCE_THRESHOLD then
			self._enemy:PivotTo(self.location)
		end
	end
end

function EnemyManager:_checkPriorityTargetDistance()
	local distance = (self._enemy.HumanoidRootPart.Position - self.hittingTarget.HumanoidRootPart.Position).Magnitude
	if distance > ATTACK_RADIUS * 2 then
		self.hittingTarget = nil
	end
end

function EnemyManager:_followTarget()
	if not self._enemy or not self._active then return end
	
	local target = self.hittingTarget or self.target
	if not target then return end
	
	-- PARALLEL: Simultaneous execution
	task.desynchronize()
	
	local targetPosition = target.PrimaryPart.Position
	local targetVelocity = target.PrimaryPart.AssemblyLinearVelocity
	local predictedPosition = targetPosition + targetVelocity * 0.5

	-- Compute a position that is DISTANCE_OFFSET studs away from the target
	local directionToTarget = (predictedPosition - self._enemy.PrimaryPart.Position).Unit
	local targetPositionWithOffset = predictedPosition - directionToTarget * DISTANCE_OFFSET

	-- Detect when the player gets closer than a certain distance to the target
	local distance = (self._enemy.PrimaryPart.Position - targetPositionWithOffset).Magnitude
	
	-- SERIAL: Sequential execution
	task.synchronize()
	
	if distance < ATTACK_RANGE then
		self.inAttackRange = true
		-- Use enemie's attack function
		self:_attackTarget()
	end
	
	self.inAttackRange = false
	self.humanoid:MoveTo(targetPositionWithOffset)
end

function EnemyManager:_followPath()
	if not self._enemy then return end
	
	while self._patrol do
		if not self.inAttackRange then
			local destination = self:_getRandomPointInCircle()
			self.humanoid:MoveTo(destination)
		end
		
		task.wait(random:NextInteger(MIN_REPOSITION_TIME, MAX_REPOSITION_TIME))
	end
end

function EnemyManager:_searchForTarget(deltaTime)
	if not self._active then return end
	
	if not self.hittingTarget then
		self.targetCheckElapsedTime = self.targetCheckElapsedTime + deltaTime
		if self.targetCheckElapsedTime >= TARGET_CHECK_INTERVAL then
			self.targetCheckElapsedTime = 0
			self.target = self:_findTarget()
		end
	end
end

function EnemyManager:_onHeartbeat(deltaTime)
	-- Check for targets periodically
	self:_searchForTarget(deltaTime)
	
	-- Follow and attack target if available
	self:_followTarget()
	
	-- Check if recently hit and handle hit effects
	self:_checkRecentlyHit(deltaTime)
	
	-- Check for teleport periodically
	self:_checkDistanceFromSpawn(deltaTime)
	
	-- Regenerate health over time
	self:_startHealthRegeneration(deltaTime)
	
	-- 
	if self.hittingTarget then
		self:_checkPriorityTargetDistance()
	end
	
	-- Update the enemy's orientation to face the direction it is moving in
	self:_updateAlignOrientation()
	
	-- Check if there are no targets and self._patrol is false
	if not self.target and not self.hittingTarget and not self._patrol then
		self:_moveToSpawnLocation()
	end
end

function EnemyManager:start()
	self._patrol = true
	
	self.corutine = coroutine.wrap(function()
		self:_followPath()
	end)()
end

function EnemyManager:stop()
	self._active = false
	self._patrol = false
	
	if self.corutine then
		coroutine.close(self.corutine)
		self.corutine = nil
	end
	
	self.humanoid.WalkSpeed = 0
end

function EnemyManager:destroy()
	self.humanoidDiedConnection:Disconnect()
	self.humanoidHealthConnection:Disconnect()
	self.humanoidRunningConnection:Disconnect()
	self.heartbeatConnection:Disconnect()
	
	--self.humanoidDiedConnection = nil
	--self.humanoidHealthConnection = nil
	--self.humanoidRunningConnection = nil
	--self.heartbeatConnection = nil
	
	if self._enemy then
		self._enemy:Destroy()
		self._enemy = nil
	end
	
	-- Cancel the previous scheduled task if it exists
	if self.respawnTask then
		task.cancel(self.respawnTask)
		self.respawnTask = nil
	end
	
	-- 
	if self.corutine then
		coroutine.close(self.corutine)
		self.corutine = nil
	end
	
	task.wait()
end

return EnemyManager

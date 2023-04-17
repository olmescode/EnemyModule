local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local AgentManager = {}
AgentManager.__index = AgentManager

function AgentManager.new(agent, path)
	local agentAbility = nil
	local self = {
		agent = agent,
		humanoid = agent.Humanoid,
		agentpath = path,
		agentAbility = agent:GetAttributes(),
		path = PathfindingService:CreatePath(agentAbility),
		waypoints = {},
		nextWaypointIndex = nil,
		blockedConnection = nil,
		reachedConnection = nil,
		enabled = true,
	}

	setmetatable(self, AgentManager)

	return self
end

function AgentManager:findTarget()
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

function AgentManager:damageTarget(target)
	local distance = (self.agent.PrimaryPart.Position - target.HumanoidRootPart.Position).Magnitude

	if distance < 8 then
		target.Humanoid.Health -= 1
	end
end

function AgentManager:getDestination()
	local destination = self.agentpath
	return destination[math.random(1, #destination)]
end

function AgentManager:spawnAgent()
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

function AgentManager:followPath()
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
					self.humanoid:MoveTo(self.waypoints[self.nextWaypointIndex].Position)
					
					if target then
						self.humanoid:MoveTo(target.HumanoidRootPart.Position)
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

return AgentManager

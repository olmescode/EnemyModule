local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local ServerStorage = game:GetService("ServerStorage")

local BasicAgents = require(ServerStorage:WaitForChild("BasicAgents"))
--require(BasicAgents)

BasicAgents.Init()

--local HalloweenEventClient = ReplicatedStorage:WaitForChild("HalloweenEventClient")
--require(HalloweenEventClient)

--local HalloweenGui = require(HalloweenEventClient.Components.HalloweenGui)
--HalloweenGui.Init()

--local setupData = require(HalloweenEvent.Components.SetupData)
--Players.PlayerAdded:Connect(setupData)

--local assets = require(MerchBooth.assets)
--local preloadAssets = require(MerchBooth.Modules.preloadAssets)()

--preloadAssets(assets)
--[[
task.spawn(function()
	ContentProvider:PreloadAsync(HalloweenEvent.Sounds:GetChildren())
end)
]]
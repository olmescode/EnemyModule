-- Makes objects like the track and enemy spawners invisible on setup
local spawnPart = workspace.Enviroment.PartCollisionBox
spawnPart.Transparency = 1

for _, part in ipairs(workspace.EnemySpawners:GetChildren()) do
	part.Transparency = 1
	part.CanCollide = false
end

for _, part in ipairs(workspace.EnemyTrack:GetChildren()) do
	part.Transparency = 1
	part.CanCollide = false
end

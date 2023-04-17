-- Makes objects like the track and enemy spawners invisible on setup
for _, part in ipairs(game.Workspace.EnemySpawners:GetChildren()) do
	part.Transparency = 1
end

for _, part in ipairs(game.Workspace.TrackParts:GetChildren()) do
	part.Transparency = 1
end

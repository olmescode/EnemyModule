# EnemyModule

A powerful and flexible enemy management system for Roblox games, supporting both client and server-side operations. This module provides an efficient way to create, manage, and control enemy behaviors in your game.

## Features

- 🤖 Easy enemy creation and management
- 🎮 Works on both server and client-side
- 🎯 Automatic player detection and targeting
- 📊 Event system for enemy state changes
- 🛣️ Allows custom creation of paths for enemies to follow
- 💥 Visual damage effects and health display
- ⚡ Optimized for creating and managing hundreds of enemies
- 🎭 Customizable animations support
- ⚔️ Customizable attack system with tool support

## Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/eff1499c-ad71-4b1e-95d6-709d8c94ec7d" width="30%">
  <img src="https://github.com/user-attachments/assets/5dd1ecbc-c294-429b-9ba6-0de782a0d3d7" width="30%">
  <img src="https://github.com/user-attachments/assets/18d50e2c-b11d-41e9-b828-17dd5e8559ce" width="30%">
</p>

## Installation

1. Clone the repository
2. Import into your Roblox project
3. Configure necessary assets:
    - Import required animations
    - Place your enemy models in the `Enemies` folder

## Basic Usage

```lua
-- Basic enemy creation
local enemy = EnemyModule.createEnemy(
    "EnemyName",          -- Name of the enemy in Enemies folder
    spawnLocation,        -- CFrame for spawn location
    animations,           -- Table of animation objects
    true                  -- Whether enemy should respawn
)

-- Start enemy patrolling
enemy:start()

-- Stop enemy
enemy:stop()

-- Clean up enemy
enemy:destroy()
```

## API Reference

### createEnemy

Creates and returns a new enemy instance.

```lua
function createEnemy(enemyName: string, spawnLocation: CFrame, animations: table, shouldRespawn: boolean): Enemy
```

* `enemyName`: string - Name of the enemy model in Enemies folder
* `spawnLocation`: CFrame - Spawn position and orientation
* `animations`: table - Animation objects for the enemy
* `shouldRespawn`: boolean - Whether the enemy should respawn after death

### createTrack

Creates a path for enemies to follow.

```lua
function createTrack(waypoints: {Vector3}): Track
```

* `waypoints`: table - Array of Vector3 positions

### Enemy Instance Methods

* `start()`: Begins enemy patrol behavior
* `stop()`: Stops enemy movement and behaviors
* `destroy()`: Cleans up the enemy instance

### Events

#### onEnemyDied

Listen for enemy death events

```lua
EnemyModule.onEnemyDied:Connect(function(enemyName: string, hittingTarget: Instance)
    print("Enemy died:", enemyName, hittingTarget)
end)
```

## Advanced Features

### Custom Attacks
The module supports two types of attack systems:

- `ToolAttackClass`: For enemies using tools/weapons
- `AttackClass`: For custom attack behaviors

### Enemy Behaviors
- **Player Detection:** Enemies can detect players within a certain range.
- **Patrolling:** Enemies can patrol around random points.
- **Path Following:** Enemies can follow predefined paths.
- **Targeting:** Enemies will target players who attack them.

### Configuration

Key parameters that can be adjusted:
- Attack radius and range
- Patrol radius
- Health regeneration rates
- Respawn times
- Detection ranges

## Contributing

Feel free to submit issues and enhancement requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

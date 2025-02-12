--[[
	EnemyModule

	Version: 1.0.0
	Author: ZX_GL
	Asset: https://www.roblox.com/library/

	This is a module for creating and managing enemies in Roblox games. It contains a 
	set of tools and assets that make it easy to add enemies to your game and control 
	their behavior.

	Folders
	* Animations: This folder contains the default animations for the enemies 
	(IdleAnim, JumpAnim, and RunAnim), which can be replaced with custom animations 
	if desired.
	* Api: This folder contains two module scripts, createEnemy and createTrack, which 
	can be used to create new enemies and tracks.
	* Attacks: This folder is where the custom model or part of an attack should be 
	placed with the name "Projectile".
	* Enemies: This folder is where the custom model of the enemies should be placed.
	* TagList: This folder contains the tags used as a reference for the project.
	* Modules: This folder contains two module scripts, AttackClass and EnemyManager, 
	which are used to define enemy attacks and manage enemy behavior.
	* Events: This folder contains a custom event called "TargetDied", which is fired 
	when a local player dies.
	
	Usage
	To use the EnemyModule in your game, follow these steps:

	1. Place the folder called "EnemySpawners" in the workspace. This folder contains 
	custom parts called "Spawner" with a string value inside called "EnemyType" where 
	you can put the name of a valid enemy that you want to spawn in that spawner. You 
	can place the spawner in any location you want.
	
	2. Place a folder called "EnemyTrack" in the workspace. This folder should contain 
	parts that define the path that the enemy will follow.
	
	3. Place a folder called "Environment" in the workspace. This folder should contain 
	a part called "PartCollisionBox", which is an important part. When the local player 
	touches it, enemies will start to spawn.
	
	API Documentation
	Configurations
	* EnemySettings: This script defines the properties of the enemy, including its size, 
	health, and attack phases.
	Here are some of the specific properties that can be adjusted:
	
	* HealthDifficulty: This determines how much damage the enemy can take before it is 
	defeated.
	* attackDamage refers to the amount of damage that the enemy's attack will deal to 
	the player.
	* attackInterval refers to the time interval between each attack in seconds.
	* numberOfAttacks refers to the total number of attacks that the enemy will perform 
	during this attack phase.
	* attackDuration refers to the duration of the attack assuming that the speed of the 
	projectiles is 10 units per second.
	
	API Functions
	* createEnemy: This script creates a new enemy using the specified enemy type, spawn 
	location, enemy difficulty, track node, and target.
	
	* createTrack: This script creates a track for an enemy using a set of waypoints 
	defined by the enemyTrack parameter.
	
	Support
	If you have any questions or issues with the EnemyModule, please contact the developer 
	or create an issue on the GitHub repository.
	
	Read more:
	
]]

extends Node2D

@onready var tilemap: TileMap = $TileMap
var map_size := Vector2i(10, 10)
var EnemyScene := preload("res://Scenes/Enemy.tscn")

func _ready():
	randomize()
	spawn_random_enemy()

func spawn_random_enemy():
	# Pick a random grid cell
	var cell: Vector2i = Vector2i(randi() % map_size.x, randi() % map_size.y)
	# Use a standard tile size of 64x64 pixels
	var tile_size: Vector2 = Vector2(64, 64)
	# Compute the world position (top-left + half cell to center)
	var world_pos: Vector2 = Vector2(cell.x * tile_size.x, cell.y * tile_size.y) + tile_size * 0.5

	# Instance and place the enemy
	var enemy = EnemyScene.instantiate()
	enemy.position = world_pos
	add_child(enemy)

	print("Spawned enemy at cell ", cell, " world_pos ", world_pos)

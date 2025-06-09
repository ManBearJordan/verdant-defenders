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
	# Get the cell size (in pixels)
	var cs: Vector2 = tilemap.get_cell_size().to_vector2()
	# Compute the world position (top-left + half cell to center)
	var world_pos: Vector2 = Vector2(cell.x * cs.x, cell.y * cs.y) + cs * 0.5

	# Instance and place the enemy
	var enemy = EnemyScene.instantiate()
	enemy.position = world_pos
	add_child(enemy)

	print("Spawned enemy at cell ", cell, " world_pos ", world_pos)

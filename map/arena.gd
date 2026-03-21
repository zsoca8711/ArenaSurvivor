extends Node2D

const WALL_THICKNESS = 50.0
const WALL_COLOR = Color(0.35, 0.3, 0.25)
const GROUND_COLOR = Color(0.18, 0.22, 0.12)
const OBSTACLE_COLOR = Color(0.45, 0.42, 0.35)


func _ready():
	_create_ground()
	_create_boundaries()
	_create_obstacles()


func _create_ground():
	var ground = ColorRect.new()
	ground.color = GROUND_COLOR
	ground.size = GameManager.ARENA_SIZE
	ground.z_index = -10
	add_child(ground)


func _create_boundaries():
	var hw = WALL_THICKNESS / 2.0
	var ax = GameManager.ARENA_SIZE.x
	var ay = GameManager.ARENA_SIZE.y
	_create_wall(Vector2(ax / 2, -hw), Vector2(ax + WALL_THICKNESS * 2, WALL_THICKNESS))
	_create_wall(Vector2(ax / 2, ay + hw), Vector2(ax + WALL_THICKNESS * 2, WALL_THICKNESS))
	_create_wall(Vector2(-hw, ay / 2), Vector2(WALL_THICKNESS, ay + WALL_THICKNESS * 2))
	_create_wall(Vector2(ax + hw, ay / 2), Vector2(WALL_THICKNESS, ay + WALL_THICKNESS * 2))


func _create_wall(pos: Vector2, size: Vector2):
	var wall = StaticBody2D.new()
	wall.collision_layer = 8
	wall.collision_mask = 0
	wall.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	wall.add_child(shape)
	var visual = ColorRect.new()
	visual.color = WALL_COLOR
	visual.size = size
	visual.position = -size / 2
	wall.add_child(visual)
	add_child(wall)


func _create_obstacles():
	# Central rock formation
	_create_obstacle(Vector2(2500, 2500), Vector2(200, 200))
	# Corner clusters
	_create_obstacle(Vector2(1000, 1000), Vector2(150, 300))
	_create_obstacle(Vector2(4000, 1000), Vector2(300, 150))
	_create_obstacle(Vector2(1000, 4000), Vector2(250, 100))
	_create_obstacle(Vector2(4000, 4000), Vector2(100, 250))
	# Long walls creating corridors
	_create_obstacle(Vector2(2500, 1500), Vector2(800, 50))
	_create_obstacle(Vector2(2500, 3500), Vector2(800, 50))
	_create_obstacle(Vector2(1500, 2500), Vector2(50, 800))
	_create_obstacle(Vector2(3500, 2500), Vector2(50, 800))


func _create_obstacle(pos: Vector2, size: Vector2):
	var obstacle = StaticBody2D.new()
	obstacle.collision_layer = 8
	obstacle.collision_mask = 0
	obstacle.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	obstacle.add_child(shape)
	var visual = ColorRect.new()
	visual.color = OBSTACLE_COLOR
	visual.size = size
	visual.position = -size / 2
	obstacle.add_child(visual)
	add_child(obstacle)

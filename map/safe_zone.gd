extends Area2D

# Safe zone — no shooting, enemies can't enter
# Enemies are pushed away from the zone boundary

var zone_size: Vector2 = Vector2(200, 200)
var farmhouse_tex = preload("res://assets/sprites/farmhouse.png")
var farm_fence_tex = preload("res://assets/sprites/farm_fence.png")
var farm_hay_tex = preload("res://assets/sprites/farm_hay.png")
var farm_corn_tex = preload("res://assets/sprites/farm_corn.png")

const PUSH_FORCE = 300.0


func _ready():
	add_to_group("safe_zones")
	collision_layer = 0
	collision_mask = 3  # Detect player (1) and enemies (2)
	_build_visual()


func _build_visual():
	var half = zone_size / 2.0

	# Ground (lighter area)
	var ground = ColorRect.new()
	ground.color = Color(0.3, 0.25, 0.18, 0.5)
	ground.size = zone_size
	ground.position = -half
	ground.z_index = -9
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)

	# Safe zone border glow
	var border = ColorRect.new()
	border.color = Color(0.2, 0.8, 0.2, 0.15)
	border.size = zone_size + Vector2(10, 10)
	border.position = -half - Vector2(5, 5)
	border.z_index = -8
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)

	# Farmhouse in center
	var house = Sprite2D.new()
	house.texture = farmhouse_tex
	house.scale = Vector2(0.35, 0.35)
	house.z_index = 2
	add_child(house)

	# Hay bales
	var hay1 = Sprite2D.new()
	hay1.texture = farm_hay_tex
	hay1.position = Vector2(randf_range(-60, -30), randf_range(20, 50))
	hay1.scale = Vector2(0.3, 0.3)
	hay1.z_index = 1
	add_child(hay1)

	var hay2 = Sprite2D.new()
	hay2.texture = farm_hay_tex
	hay2.position = Vector2(randf_range(30, 60), randf_range(-40, -10))
	hay2.scale = Vector2(0.3, 0.3)
	hay2.z_index = 1
	add_child(hay2)

	# Corn around the edges
	for i in randi_range(3, 6):
		var corn = Sprite2D.new()
		corn.texture = farm_corn_tex
		corn.position = Vector2(randf_range(-half.x + 10, half.x - 10), randf_range(-half.y + 10, half.y - 10))
		corn.scale = Vector2(0.25, 0.25)
		corn.z_index = 1
		add_child(corn)

	# "SAFE ZONE" label
	var label = Label.new()
	label.text = "SAFE ZONE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-50, -half.y - 20)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 10
	add_child(label)

	# Collision shape
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = zone_size
	shape.shape = rect
	add_child(shape)


func _physics_process(delta):
	# Push enemies away from safe zone
	for body in get_overlapping_bodies():
		if body.is_in_group("enemies"):
			var push_dir = (body.global_position - global_position).normalized()
			body.velocity = push_dir * PUSH_FORCE
			body.move_and_slide()

	# Check if player is inside — disable shooting
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.in_safe_zone = _is_inside(player.global_position)


func _is_inside(pos: Vector2) -> bool:
	var half = zone_size / 2.0
	return abs(pos.x - global_position.x) < half.x and abs(pos.y - global_position.y) < half.y

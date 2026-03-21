extends Area2D

# Safe zone — no shooting, enemies can't enter
# Enemies are pushed away from the zone boundary

var zone_size: Vector2 = Vector2(300, 300)
var farmhouse_tex = preload("res://assets/sprites/farmhouse.png")
var farm_fence_tex = preload("res://assets/sprites/farm_fence.png")
var farm_hay_tex = preload("res://assets/sprites/farm_hay.png")
var farm_corn_tex = preload("res://assets/sprites/farm_corn.png")

const PUSH_FORCE = 300.0
var MAX_STAY_TIME: float = 10.0

var stay_timer: float = 0.0
var protection_active: bool = true
var timer_label: Label


func _ready():
	add_to_group("safe_zones")
	collision_layer = 0
	collision_mask = 3  # Detect player (1) and enemies (2)
	MAX_STAY_TIME = GameManager.get_safe_zone_time()
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
	timer_label = Label.new()
	timer_label.text = "SAFE ZONE"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.position = Vector2(-50, -half.y - 20)
	timer_label.add_theme_font_size_override("font_size", 14)
	timer_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_label.z_index = 10
	add_child(timer_label)

	# Collision shape
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = zone_size
	shape.shape = rect
	add_child(shape)


func _physics_process(delta):
	var player = get_tree().get_first_node_in_group("player")
	var player_inside = player and _is_inside(player.global_position)

	if player_inside:
		stay_timer += delta
		if stay_timer >= MAX_STAY_TIME:
			protection_active = false
	else:
		# Reset when player leaves
		stay_timer = 0.0
		protection_active = true

	# Push enemies away only if protection is active
	if protection_active:
		for body in get_overlapping_bodies():
			if body.is_in_group("enemies"):
				var push_dir = (body.global_position - global_position).normalized()
				body.velocity = push_dir * PUSH_FORCE
				body.move_and_slide()

	# Update player safe zone state
	if player:
		player.in_safe_zone = player_inside and protection_active

	# Update label
	if player_inside and protection_active:
		var remaining = MAX_STAY_TIME - stay_timer
		timer_label.text = "SAFE ZONE  %ds" % ceili(remaining)
		timer_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2) if remaining > 3 else Color(1, 0.3, 0.1))
	elif not protection_active:
		timer_label.text = "EXPIRED!"
		timer_label.add_theme_color_override("font_color", Color(1, 0.1, 0.1))
	else:
		timer_label.text = "SAFE ZONE"
		timer_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))


func _is_inside(pos: Vector2) -> bool:
	var half = zone_size / 2.0
	return abs(pos.x - global_position.x) < half.x and abs(pos.y - global_position.y) < half.y

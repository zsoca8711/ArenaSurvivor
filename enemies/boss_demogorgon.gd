extends CharacterBody2D

# Demogorgon — flower monster, only flamethrower can damage it!
@export var speed: float = 100.0
@export var max_hp: float = 500.0
@export var contact_damage: float = 40.0
@export var money_reward: int = 3000

var hp: float
var target: Node2D


func _ready():
	hp = max_hp
	add_to_group("enemies")
	add_to_group("bosses")
	_find_target()
	_build_visual()


func _build_visual():
	var body = $Body
	var petal_count = 8

	# 8 petals (brown with red edges)
	for i in petal_count:
		var angle = i * TAU / petal_count

		# Brown edge petal (slightly larger, drawn first)
		var brown_petal = Polygon2D.new()
		brown_petal.color = Color(0.45, 0.28, 0.15)
		brown_petal.polygon = _make_petal(28, 13)
		brown_petal.rotation = angle
		body.add_child(brown_petal)

		# Red inner petal
		var red_petal = Polygon2D.new()
		red_petal.color = Color(0.85, 0.12, 0.08)
		red_petal.polygon = _make_petal(24, 10)
		red_petal.rotation = angle
		body.add_child(red_petal)

		# Teeth on petal tips (2 white triangles per petal)
		var tooth1 = Polygon2D.new()
		tooth1.color = Color(0.95, 0.93, 0.85)
		tooth1.polygon = PackedVector2Array([Vector2(24, -3), Vector2(30, 0), Vector2(24, 3)])
		tooth1.rotation = angle
		body.add_child(tooth1)

		var tooth2 = Polygon2D.new()
		tooth2.color = Color(0.95, 0.93, 0.85)
		tooth2.polygon = PackedVector2Array([Vector2(20, -5), Vector2(27, -1), Vector2(20, 1)])
		tooth2.rotation = angle
		body.add_child(tooth2)

		var tooth3 = Polygon2D.new()
		tooth3.color = Color(0.95, 0.93, 0.85)
		tooth3.polygon = PackedVector2Array([Vector2(20, 5), Vector2(27, 1), Vector2(20, -1)])
		tooth3.rotation = angle
		body.add_child(tooth3)

	# Dark center hole
	var center_bg = Polygon2D.new()
	center_bg.color = Color(0.15, 0.05, 0.05)
	center_bg.polygon = _make_circle(12, 16)
	body.add_child(center_bg)

	# Inner ring of teeth around the center hole (16 teeth pointing inward)
	for i in 16:
		var angle = i * TAU / 16
		var tooth = Polygon2D.new()
		tooth.color = Color(0.95, 0.93, 0.85)
		var tip_dist = 7.0
		var base_dist = 13.0
		var spread = TAU / 48
		tooth.polygon = PackedVector2Array([
			Vector2(cos(angle) * tip_dist, sin(angle) * tip_dist),
			Vector2(cos(angle - spread) * base_dist, sin(angle - spread) * base_dist),
			Vector2(cos(angle + spread) * base_dist, sin(angle + spread) * base_dist),
		])
		body.add_child(tooth)

	# Deep center (the throat)
	var throat = Polygon2D.new()
	throat.color = Color(0.08, 0.0, 0.0)
	throat.polygon = _make_circle(6, 12)
	body.add_child(throat)


func _make_petal(length: float, width: float) -> PackedVector2Array:
	# Teardrop/petal shape pointing right (positive X)
	return PackedVector2Array([
		Vector2(4, 0),
		Vector2(length * 0.4, -width * 0.7),
		Vector2(length * 0.7, -width),
		Vector2(length, -width * 0.3),
		Vector2(length + 2, 0),
		Vector2(length, width * 0.3),
		Vector2(length * 0.7, width),
		Vector2(length * 0.4, width * 0.7),
	])


func _make_circle(radius: float, segments: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in segments:
		var angle = i * TAU / segments
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	return points


func _physics_process(_delta):
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		rotation = direction.angle()


func _find_target():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]


func take_damage(amount: float, source_color: Color = Color.WHITE):
	# Only flamethrower (orange color) can damage the Demogorgon
	if not _is_flamethrower(source_color):
		return
	hp -= amount
	$Body.modulate = Color(1, 0.3, 0.3)
	get_tree().create_timer(0.05).timeout.connect(
		func():
			if is_instance_valid(self):
				$Body.modulate = Color(1, 1, 1)
	)
	if hp <= 0:
		die()


func _is_flamethrower(color: Color) -> bool:
	return color.r > 0.9 and color.g > 0.3 and color.g < 0.7 and color.b < 0.2


func die():
	GameManager.add_money(money_reward)
	GameManager.enemy_killed()
	WaveManager.enemy_died()
	GameManager.try_drop_loot(global_position)
	GameManager.try_drop_loot(global_position)
	GameManager.try_drop_loot(global_position)
	call_deferred("queue_free")

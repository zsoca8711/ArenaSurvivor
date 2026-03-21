extends CharacterBody2D

# Vecna — teleports and shoots homing dark vines like Radio Staff
@export var speed: float = 80.0
@export var max_hp: float = 800.0
@export var contact_damage: float = 35.0
@export var money_reward: int = 4000

var hp: float
var target: Node2D
var fire_timer: float = 0.0
var teleport_timer: float = 0.0
var bullet_scene = preload("res://weapons/bullet.tscn")

const FIRE_RATE = 0.6
const TELEPORT_COOLDOWN = 5.0
const TELEPORT_RANGE = 400.0


func _ready():
	hp = max_hp
	add_to_group("enemies")
	add_to_group("bosses")
	_find_target()
	_build_visual()
	fire_timer = 1.0
	teleport_timer = 3.0


func _build_visual():
	var body = $Body
	# Dark humanoid shape with tendrils
	# Main body - dark twisted form
	var torso = Polygon2D.new()
	torso.color = Color(0.15, 0.1, 0.12)
	torso.polygon = PackedVector2Array([
		Vector2(0, -20), Vector2(12, -10), Vector2(14, 5),
		Vector2(10, 18), Vector2(0, 22), Vector2(-10, 18),
		Vector2(-14, 5), Vector2(-12, -10)
	])
	body.add_child(torso)

	# Head
	var head = Polygon2D.new()
	head.color = Color(0.25, 0.15, 0.15)
	head.polygon = _make_circle(8, 10)
	head.position = Vector2(0, -24)
	body.add_child(head)

	# Glowing red eye
	var eye = Polygon2D.new()
	eye.color = Color(1, 0.1, 0.1)
	eye.polygon = _make_circle(3, 8)
	eye.position = Vector2(2, -25)
	body.add_child(eye)

	# 6 tendrils/vines extending outward
	for i in 6:
		var angle = i * TAU / 6 + PI / 6
		var tendril = Polygon2D.new()
		tendril.color = Color(0.08, 0.02, 0.05)
		var tip = Vector2(cos(angle) * 28, sin(angle) * 28)
		var mid = Vector2(cos(angle) * 16, sin(angle) * 16)
		var spread = Vector2(cos(angle + 0.3) * 4, sin(angle + 0.3) * 4)
		tendril.polygon = PackedVector2Array([
			mid - spread, tip, mid + spread
		])
		body.add_child(tendril)


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


func _process(delta):
	if not target or not is_instance_valid(target):
		_find_target()
		return

	# Shoot homing vines
	fire_timer -= delta
	if fire_timer <= 0:
		_fire_vine()
		fire_timer = FIRE_RATE

	# Teleport
	teleport_timer -= delta
	if teleport_timer <= 0:
		_teleport()
		teleport_timer = TELEPORT_COOLDOWN


func _find_target():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]


func _fire_vine():
	var vine = bullet_scene.instantiate()
	vine.global_position = global_position + Vector2.from_angle(rotation) * 20
	vine.rotation = rotation
	vine.speed = 400.0
	vine.damage = 12.0
	vine.lifetime = 4.0
	vine.bullet_color = Color(0.08, 0.0, 0.08)
	vine.homing = true
	vine.from_boss = true
	# Vines target players, not enemies
	vine.collision_layer = 0
	vine.collision_mask = 9  # Player (1) + Walls (8)
	get_tree().current_scene.call_deferred("add_child", vine)


func _teleport():
	if not target or not is_instance_valid(target):
		return
	# Teleport to a random position near the player
	var angle = randf() * TAU
	var dist = randf_range(200, TELEPORT_RANGE)
	var new_pos = target.global_position + Vector2(cos(angle) * dist, sin(angle) * dist)
	# Clamp to arena
	var arena = GameManager.ARENA_SIZE
	new_pos.x = clamp(new_pos.x, 50, arena.x - 50)
	new_pos.y = clamp(new_pos.y, 50, arena.y - 50)
	# Visual flash
	$Body.modulate = Color(0.5, 0, 0.5)
	global_position = new_pos
	get_tree().create_timer(0.2).timeout.connect(
		func():
			if is_instance_valid(self):
				$Body.modulate = Color(1, 1, 1)
	)


func take_damage(amount: float, _source_color: Color = Color.WHITE):
	hp -= amount
	$Body.modulate = Color(1, 0.3, 0.3)
	get_tree().create_timer(0.05).timeout.connect(
		func():
			if is_instance_valid(self):
				$Body.modulate = Color(1, 1, 1)
	)
	if hp <= 0:
		die()


func die():
	GameManager.add_money(money_reward)
	GameManager.enemy_killed()
	WaveManager.enemy_died()
	GameManager.try_drop_loot(global_position)
	GameManager.try_drop_loot(global_position)
	GameManager.try_drop_loot(global_position)
	call_deferred("queue_free")

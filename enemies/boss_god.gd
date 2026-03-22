extends CharacterBody2D

# God — white/yellow laser beam, 10 HP/sec damage
@export var speed: float = 50.0
@export var max_hp: float = 3000.0
@export var contact_damage: float = 25.0
@export var money_reward: int = 8000

var hp: float
var target: Node2D
var laser_active: bool = false
var laser_timer: float = 0.0
var laser_cooldown: float = 0.0
var laser_line: Line2D

const LASER_RANGE = 700.0
const LASER_COOLDOWN = 4.0
const LASER_DURATION = 3.0
const LASER_DPS = 10.0


func _ready():
	hp = max_hp
	add_to_group("enemies")
	add_to_group("bosses")
	_find_target()
	_build_visual()
	laser_cooldown = 2.0


func _build_visual():
	var body = $Body

	# Glowing white/yellow divine form
	# Outer glow
	var glow = Polygon2D.new()
	glow.color = Color(1, 0.95, 0.6, 0.3)
	glow.polygon = _make_circle(35, 16)
	body.add_child(glow)

	# Main body - bright white
	var main = Polygon2D.new()
	main.color = Color(1, 1, 0.9)
	main.polygon = _make_circle(22, 12)
	body.add_child(main)

	# Inner core - light yellow
	var core = Polygon2D.new()
	core.color = Color(1, 0.95, 0.5)
	core.polygon = _make_circle(14, 10)
	body.add_child(core)

	# 8 light rays extending outward
	for i in 8:
		var angle = i * TAU / 8
		var ray = Polygon2D.new()
		ray.color = Color(1, 0.98, 0.7, 0.6)
		var tip = Vector2(cos(angle) * 40, sin(angle) * 40)
		var side1 = Vector2(cos(angle - 0.15) * 18, sin(angle - 0.15) * 18)
		var side2 = Vector2(cos(angle + 0.15) * 18, sin(angle + 0.15) * 18)
		ray.polygon = PackedVector2Array([side1, tip, side2])
		body.add_child(ray)

	# Central eye
	var eye = Polygon2D.new()
	eye.color = Color(1, 0.9, 0.3)
	eye.polygon = _make_circle(5, 8)
	body.add_child(eye)

	# Laser line
	laser_line = Line2D.new()
	laser_line.width = 8.0
	laser_line.default_color = Color(1, 1, 0.7, 0.9)
	laser_line.visible = false
	laser_line.z_index = 5
	add_child(laser_line)


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


func _process(delta):
	if not target or not is_instance_valid(target):
		_find_target()
		return

	if laser_active:
		laser_timer -= delta
		_update_laser(delta)
		if laser_timer <= 0:
			_end_laser()
	else:
		laser_cooldown -= delta
		if laser_cooldown <= 0:
			var dist = global_position.distance_to(target.global_position)
			if dist <= LASER_RANGE:
				_start_laser()
				laser_cooldown = LASER_COOLDOWN


func _find_target():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]


func _start_laser():
	laser_active = true
	laser_timer = LASER_DURATION
	laser_line.visible = true


func _update_laser(delta):
	if target and is_instance_valid(target):
		laser_line.clear_points()
		laser_line.add_point(Vector2.ZERO)
		laser_line.add_point(target.global_position - global_position)
		# Pulsing white/yellow
		var pulse = 0.7 + sin(laser_timer * 12) * 0.3
		laser_line.default_color = Color(1, 1 * pulse, 0.5 * pulse, 0.9)
		# Deal damage per second (not in safe zone)
		if not target.in_safe_zone:
			target._last_damage_source_is_boss = true
			target.take_damage(LASER_DPS * delta)


func _end_laser():
	laser_active = false
	laser_line.visible = false


func take_damage(amount: float, _source_color: Color = Color.WHITE):
	hp -= amount
	$Body.modulate = Color(0.8, 0.8, 0.5)
	get_tree().create_timer(0.05).timeout.connect(
		func():
			if is_instance_valid(self):
				$Body.modulate = Color(1, 1, 1)
	)
	if hp <= 0:
		die()


func die():
	_end_laser()
	GameManager.add_money(money_reward)
	GameManager.enemy_killed()
	WaveManager.enemy_died()
	GameManager.try_drop_loot(global_position)
	GameManager.try_drop_loot(global_position)
	GameManager.try_drop_loot(global_position)
	call_deferred("queue_free")

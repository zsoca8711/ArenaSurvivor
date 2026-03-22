extends CharacterBody2D

# Mind Flayer — fires blue beam that halves player HP (can't kill, only weaken)
@export var speed: float = 60.0
@export var max_hp: float = 1000.0
@export var contact_damage: float = 20.0
@export var money_reward: int = 5000

var hp: float
var target: Node2D
var beam_timer: float = 0.0
var beam_active: bool = false
var beam_duration: float = 0.0
var beam_line: Line2D

const BEAM_COOLDOWN = 6.0
const BEAM_DURATION = 1.5
const BEAM_RANGE = 600.0


func _ready():
	hp = max_hp
	add_to_group("enemies")
	add_to_group("bosses")
	_find_target()
	_build_visual()
	beam_timer = 3.0


func _build_visual():
	var body = $Body

	# Large dark mass - the main body
	var mass = Polygon2D.new()
	mass.color = Color(0.1, 0.08, 0.15)
	mass.polygon = PackedVector2Array([
		Vector2(0, -25), Vector2(18, -18), Vector2(25, 0),
		Vector2(18, 18), Vector2(0, 25), Vector2(-18, 18),
		Vector2(-25, 0), Vector2(-18, -18)
	])
	body.add_child(mass)

	# Inner glow (dark blue)
	var inner = Polygon2D.new()
	inner.color = Color(0.12, 0.1, 0.25)
	inner.polygon = _make_circle(16, 12)
	body.add_child(inner)

	# Multiple tentacles hanging down
	for i in 8:
		var angle = i * TAU / 8
		var tentacle = Polygon2D.new()
		tentacle.color = Color(0.08, 0.05, 0.12)
		var base = Vector2(cos(angle) * 18, sin(angle) * 18)
		var tip = Vector2(cos(angle) * 35, sin(angle) * 35)
		var side = Vector2(cos(angle + 0.2) * 3, sin(angle + 0.2) * 3)
		tentacle.polygon = PackedVector2Array([
			base - side, tip, base + side
		])
		body.add_child(tentacle)

	# Central blue eye
	var eye_outer = Polygon2D.new()
	eye_outer.color = Color(0.2, 0.3, 0.8)
	eye_outer.polygon = _make_circle(6, 10)
	body.add_child(eye_outer)

	var eye_inner = Polygon2D.new()
	eye_inner.color = Color(0.0, 0.1, 0.4)
	eye_inner.polygon = _make_circle(3, 8)
	body.add_child(eye_inner)

	# Beam line (hidden by default)
	beam_line = Line2D.new()
	beam_line.width = 6.0
	beam_line.default_color = Color(0.2, 0.4, 1.0, 0.8)
	beam_line.visible = false
	beam_line.z_index = 5
	add_child(beam_line)


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

	if beam_active:
		beam_duration -= delta
		_update_beam()
		if beam_duration <= 0:
			_end_beam()
	else:
		beam_timer -= delta
		if beam_timer <= 0:
			var dist = global_position.distance_to(target.global_position)
			if dist <= BEAM_RANGE:
				_start_beam()
				beam_timer = BEAM_COOLDOWN


func _find_target():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]


func _start_beam():
	beam_active = true
	beam_duration = BEAM_DURATION
	beam_line.visible = true
	# Halve the player's HP (can't kill, not in safe zone)
	if target and is_instance_valid(target) and not target.in_safe_zone:
		var halved = target.hp / 2.0
		target.hp = halved
		target.hp = max(target.hp, 1.0)
		GameManager.health_changed.emit(target.hp, target.max_hp)


func _update_beam():
	if target and is_instance_valid(target):
		beam_line.clear_points()
		beam_line.add_point(Vector2.ZERO)
		beam_line.add_point(target.global_position - global_position)
		# Pulsing color
		var pulse = 0.5 + sin(beam_duration * 15) * 0.3
		beam_line.default_color = Color(0.2, 0.4 * pulse, 1.0, 0.7 + pulse * 0.3)


func _end_beam():
	beam_active = false
	beam_line.visible = false


func take_damage(amount: float, _source_color: Color = Color.WHITE):
	hp -= amount
	$Body.modulate = Color(0.5, 0.5, 1.0)
	get_tree().create_timer(0.05).timeout.connect(
		func():
			if is_instance_valid(self):
				$Body.modulate = Color(1, 1, 1)
	)
	if hp <= 0:
		die()


func die():
	_end_beam()
	GameManager.add_money(money_reward)
	GameManager.enemy_killed()
	WaveManager.enemy_died()
	GameManager.try_drop_loot(global_position)
	GameManager.try_drop_loot(global_position)
	GameManager.try_drop_loot(global_position)
	call_deferred("queue_free")

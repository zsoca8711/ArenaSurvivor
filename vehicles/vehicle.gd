extends CharacterBody2D

enum VehicleType {MOTOR, CAR, TANK}

@export var vehicle_type: VehicleType = VehicleType.MOTOR
@export var max_hp: float = 500.0
@export var drive_speed: float = 350.0

var hp: float
var occupied: bool = false
var driver: Node2D = null
var is_destroyed: bool = false
var enter_cooldown: float = 0.0
var explode_timer: float = -1.0
var laser_line: Line2D
var tank_fire_cooldown: float = 0.0
var bullet_scene = preload("res://weapons/bullet.tscn")

const TANK_FIRE_COOLDOWN = 2.0
const EXPLODE_DELAY = 5.0
const EXPLODE_RADIUS = 50.0


func _ready():
	hp = max_hp
	add_to_group("vehicles")

	# Tank laser sight
	if vehicle_type == VehicleType.TANK:
		laser_line = Line2D.new()
		laser_line.width = 2.0
		laser_line.default_color = Color(1, 0, 0, 0.5)
		laser_line.visible = false
		laser_line.z_index = 3
		add_child(laser_line)


func _physics_process(_delta):
	if is_destroyed:
		return
	if occupied and driver and is_instance_valid(driver):
		# Drive with WASD
		var input = Vector2.ZERO
		input.x = Input.get_axis("move_left", "move_right")
		input.y = Input.get_axis("move_up", "move_down")
		velocity = input.normalized() * drive_speed
		move_and_slide()
		look_at(get_global_mouse_position())
		# Keep driver at vehicle position
		driver.global_position = global_position


func _process(delta):
	if is_destroyed:
		if explode_timer >= 0:
			explode_timer -= delta
			# Flash red warning
			$Body.modulate = Color(1, 0.2, 0.2) if fmod(explode_timer, 0.4) < 0.2 else Color(1, 0.6, 0.2)
			if explode_timer <= 0:
				_explode()
		return

	if not occupied:
		return

	# Tank shooting
	if vehicle_type == VehicleType.TANK:
		tank_fire_cooldown -= delta
		_update_laser()
		if Input.is_action_pressed("fire") and tank_fire_cooldown <= 0:
			_tank_fire()
			tank_fire_cooldown = TANK_FIRE_COOLDOWN

	# Contact damage handling
	_handle_vehicle_damage(delta)

	# Exit with F (cooldown prevents instant exit after entering)
	enter_cooldown -= delta
	if Input.is_action_just_pressed("enter_vehicle") and enter_cooldown <= 0:
		exit_vehicle()


func _handle_vehicle_damage(delta):
	if not occupied or driver == null:
		return
	for body in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(body.global_position) > 40:
			continue
		match vehicle_type:
			VehicleType.MOTOR:
				# Melee enemies CAN damage
				take_vehicle_damage(body.contact_damage * delta * 2)
			VehicleType.CAR:
				# Melee enemies CANNOT damage - car is protected
				pass
			VehicleType.TANK:
				# Tank is fully protected from melee
				pass


func _update_laser():
	if laser_line == null:
		return
	laser_line.visible = occupied
	if occupied:
		laser_line.clear_points()
		laser_line.add_point(Vector2.ZERO)
		var aim_dir = Vector2.from_angle(rotation)
		laser_line.add_point(aim_dir * 500)
		if tank_fire_cooldown <= 0:
			laser_line.default_color = Color(1, 0, 0, 0.7)
		else:
			laser_line.default_color = Color(1, 0, 0, 0.2)


func _tank_fire():
	var b = bullet_scene.instantiate()
	b.global_position = global_position + Vector2.from_angle(rotation) * 30
	b.rotation = rotation
	b.speed = 1000
	b.damage = 100
	b.lifetime = 4.0
	b.aoe_radius = 80.0
	b.bullet_color = Color(0.8, 0.2, 0.0)
	get_tree().current_scene.call_deferred("add_child", b)


func enter_vehicle(player: Node2D):
	if occupied or is_destroyed:
		return
	occupied = true
	enter_cooldown = 0.5
	driver = player
	driver.visible = false
	driver.set_physics_process(false)
	driver.set_process(false)
	# Player stops shooting
	driver.global_position = global_position


func exit_vehicle():
	if not occupied or driver == null:
		return
	occupied = false
	driver.visible = true
	driver.set_physics_process(true)
	driver.set_process(true)
	driver.global_position = global_position + Vector2(40, 0)
	driver.in_vehicle = false
	if laser_line:
		laser_line.visible = false
	driver = null


func take_vehicle_damage(amount: float):
	if is_destroyed:
		return
	hp -= amount
	$Body.modulate = Color(1, 0.4, 0.4)
	get_tree().create_timer(0.1).timeout.connect(
		func():
			if is_instance_valid(self) and not is_destroyed:
				$Body.modulate = Color(1, 1, 1)
	)
	if hp <= 0:
		_on_destroyed()


func _on_destroyed():
	is_destroyed = true
	if occupied and driver:
		exit_vehicle()
	explode_timer = EXPLODE_DELAY
	$Body.modulate = Color(0.5, 0.3, 0.1)


func _explode():
	# Kill everything in radius
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(enemy.global_position) <= EXPLODE_RADIUS:
			enemy.take_damage(99999.0)
	# Damage player if nearby
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) <= EXPLODE_RADIUS:
		player.take_damage(50.0)
	# Visual explosion
	var boom = Polygon2D.new()
	boom.color = Color(1, 0.5, 0.0, 0.7)
	boom.polygon = _make_circle(EXPLODE_RADIUS, 16)
	boom.global_position = global_position
	boom.z_index = 10
	get_tree().current_scene.add_child(boom)
	var tween = boom.create_tween()
	tween.tween_property(boom, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(boom.queue_free)
	call_deferred("queue_free")


func _make_circle(radius: float, segments: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in segments:
		var angle = i * TAU / segments
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	return points

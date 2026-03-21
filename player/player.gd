extends CharacterBody2D

@export var speed: float = 300.0
@export var max_hp: float = 100.0
@export var bullet_scene: PackedScene

var hp: float
var can_fire: bool = true
var is_dead: bool = false
var damage_cooldown: float = 0.0
var damage_bonus: float = 0.0
var fire_rate_bonus: float = 0.0
var invincible: bool = false

const DAMAGE_COOLDOWN_TIME = 0.5

# Weapon system
const WEAPONS = {
	"pistol": {"name": "Pistol", "damage": 10, "fire_rate": 0.3, "speed": 800, "spread": 0.0, "bullets": 1, "lifetime": 3.0, "aoe": 0.0, "color": Color(1, 0.9, 0.2)},
	"shotgun": {"name": "Shotgun", "damage": 8, "fire_rate": 0.8, "speed": 600, "spread": 15.0, "bullets": 5, "lifetime": 1.5, "aoe": 0.0, "color": Color(1, 0.6, 0.2)},
	"smg": {"name": "SMG", "damage": 6, "fire_rate": 0.08, "speed": 700, "spread": 5.0, "bullets": 1, "lifetime": 3.0, "aoe": 0.0, "color": Color(0.8, 0.8, 0.2)},
	"rifle": {"name": "Rifle", "damage": 40, "fire_rate": 1.2, "speed": 1200, "spread": 0.0, "bullets": 1, "lifetime": 3.0, "aoe": 0.0, "color": Color(0.3, 0.9, 1.0)},
	"rocket_launcher": {"name": "Rocket Launcher", "damage": 80, "fire_rate": 2.0, "speed": 400, "spread": 0.0, "bullets": 1, "lifetime": 5.0, "aoe": 120.0, "color": Color(1, 0.3, 0.1)},
	"flamethrower": {"name": "Flamethrower", "damage": 3, "fire_rate": 0.03, "speed": 300, "spread": 12.0, "bullets": 1, "lifetime": 0.4, "aoe": 0.0, "color": Color(1, 0.5, 0.0)},
	"minigun": {"name": "Minigun", "damage": 12, "fire_rate": 0.05, "speed": 750, "spread": 8.0, "bullets": 1, "lifetime": 3.0, "aoe": 0.0, "color": Color(0.7, 0.7, 0.7)},
	"radio_staff": {"name": "Radio Staff", "damage": 15, "fire_rate": 0.4, "speed": 600, "spread": 0.0, "bullets": 1, "lifetime": 5.0, "aoe": 0.0, "color": Color(0.1, 0.0, 0.1), "homing": true},
	"megacluster_cannon": {"name": "Megacluster Cannon", "damage": 80, "fire_rate": 0.08, "speed": 500, "spread": 15.0, "bullets": 3, "lifetime": 4.0, "aoe": 120.0, "color": Color(1, 0.15, 0.0)},
}

var weapons_owned: Dictionary = {"pistol": -1}  # weapon_id -> ammo (-1 = infinite)
var current_weapon: String = "pistol"
var summon_cooldown: float = 0.0
const SUMMON_COOLDOWN_TIME = 3.0
var minion_scene = preload("res://player/minion.tscn")
var radio_demon_scene = preload("res://player/radio_demon.tscn")
var radio_staff_kills: int = 0
var has_telekinetic: bool = false
var telekinetic_cooldown: float = 0.0
const TELEKINETIC_COOLDOWN_TIME = 10.0
const TELEKINETIC_RADIUS = 100.0


func _ready():
	hp = max_hp
	add_to_group("player")


func _is_local() -> bool:
	return not NetworkManager.is_online or is_multiplayer_authority()


func _physics_process(_delta):
	if is_dead:
		return
	if _is_local():
		_handle_movement()
		_handle_aim()
		if NetworkManager.is_online:
			_sync_position.rpc(global_position, rotation)


func _process(delta):
	if is_dead:
		return
	if _is_local():
		_handle_shooting()
		_handle_summon(delta)
		_handle_telekinetic(delta)
		_process_contact_damage(delta)


@rpc("any_peer", "unreliable")
func _sync_position(pos: Vector2, rot: float):
	if not _is_local():
		global_position = pos
		rotation = rot


func _handle_summon(delta):
	summon_cooldown -= delta
	if current_weapon == "radio_staff" and Input.is_action_just_pressed("summon") and summon_cooldown <= 0:
		var minion = minion_scene.instantiate()
		minion.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		minion.owner_player = self
		get_tree().current_scene.call_deferred("add_child", minion)
		summon_cooldown = SUMMON_COOLDOWN_TIME


func _handle_telekinetic(delta):
	telekinetic_cooldown -= delta
	if has_telekinetic and Input.is_action_just_pressed("ability_1") and telekinetic_cooldown <= 0:
		telekinetic_cooldown = TELEKINETIC_COOLDOWN_TIME
		# Kill everything in radius
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if global_position.distance_to(enemy.global_position) <= TELEKINETIC_RADIUS:
				enemy.take_damage(99999.0)
		# Visual pulse
		_spawn_telekinetic_wave()


func _spawn_telekinetic_wave():
	# Purple expanding circle effect
	var wave = Polygon2D.new()
	wave.color = Color(0.6, 0.1, 0.9, 0.5)
	var points = PackedVector2Array()
	for i in 24:
		var angle = i * TAU / 24
		points.append(Vector2(cos(angle) * TELEKINETIC_RADIUS, sin(angle) * TELEKINETIC_RADIUS))
	wave.polygon = points
	wave.global_position = global_position
	wave.z_index = 10
	get_tree().current_scene.add_child(wave)
	var tween = wave.create_tween()
	tween.tween_property(wave, "scale", Vector2(1.5, 1.5), 0.5)
	tween.parallel().tween_property(wave, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(wave.queue_free)


func on_radio_staff_kill():
	radio_staff_kills += 1
	if radio_staff_kills % 100 == 0:
		_spawn_radio_demon()


func _spawn_radio_demon():
	var demon = radio_demon_scene.instantiate()
	demon.global_position = global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
	demon.owner_player = self
	get_tree().current_scene.call_deferred("add_child", demon)


var in_vehicle: bool = false


func _input(event):
	if is_dead or get_tree().paused:
		return
	# Enter nearby vehicle with E
	if event.is_action_pressed("open_shop") and not in_vehicle:
		var nearest = _find_nearest_vehicle()
		if nearest and not WaveManager.buy_phase_active:
			nearest.enter_vehicle(self)
			in_vehicle = true
			get_viewport().set_input_as_handled()


func _find_nearest_vehicle() -> Node2D:
	var min_dist = 60.0
	var nearest = null
	for v in get_tree().get_nodes_in_group("vehicles"):
		if v.is_destroyed or v.occupied:
			continue
		var dist = global_position.distance_to(v.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = v
	return nearest


func _handle_movement():
	var input = Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")
	velocity = input.normalized() * min(speed, 200.0)
	move_and_slide()


func _handle_aim():
	look_at(get_global_mouse_position())


func _handle_shooting():
	if Input.is_action_pressed("fire") and can_fire:
		_fire()


func _fire():
	if bullet_scene == null:
		return
	var weapon = WEAPONS[current_weapon]
	can_fire = false
	for i in weapon["bullets"]:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = $Muzzle.global_position
		var spread_angle = deg_to_rad(randf_range(-weapon["spread"], weapon["spread"]))
		bullet.rotation = rotation + spread_angle
		bullet.speed = weapon["speed"]
		bullet.damage = weapon["damage"] + damage_bonus
		bullet.lifetime = weapon["lifetime"]
		bullet.aoe_radius = weapon["aoe"]
		bullet.bullet_color = weapon["color"]
		if weapon.get("homing", false):
			bullet.homing = true
		get_tree().current_scene.add_child(bullet)
	var rate = max(0.02, weapon["fire_rate"] - fire_rate_bonus)
	$FireTimer.start(rate)


func _switch_weapon(direction: int):
	var owned = weapons_owned.keys()
	if owned.size() <= 1:
		return
	var idx = owned.find(current_weapon)
	idx = (idx + direction) % owned.size()
	if idx < 0:
		idx += owned.size()
	current_weapon = owned[idx]


func add_weapon(weapon_id: String, _ammo: int = 0):
	# Only one weapon at a time — replace current
	weapons_owned.clear()
	weapons_owned[weapon_id] = -1  # All weapons have infinite ammo
	current_weapon = weapon_id


func add_ammo(_amount: int):
	pass  # All weapons have infinite ammo


func get_ammo_text() -> String:
	return "INF"


func get_weapon_name() -> String:
	return WEAPONS[current_weapon]["name"]


var _last_damage_source_is_boss: bool = false


func _process_contact_damage(delta):
	damage_cooldown -= delta
	if damage_cooldown > 0:
		return
	for body in $Hurtbox.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			_last_damage_source_is_boss = body.is_in_group("bosses")
			take_damage(body.contact_damage)
			damage_cooldown = DAMAGE_COOLDOWN_TIME
			break


func take_damage(amount: float):
	if is_dead or invincible:
		return
	hp -= amount
	hp = max(hp, 0)
	GameManager.health_changed.emit(hp, max_hp)
	$Body.modulate = Color(1, 0.3, 0.3)
	get_tree().create_timer(0.1).timeout.connect(
		func():
			if is_instance_valid(self):
				$Body.modulate = Color(1, 1, 1)
	)
	if hp <= 0:
		if _last_damage_source_is_boss:
			_boss_death()
		else:
			_die()


func _die():
	is_dead = true
	$Body.modulate = Color(0.5, 0.5, 0.5, 0.5)
	GameManager.on_player_died()


func _boss_death():
	# Boss kill: no game over, respawn with 10% max HP, skip to next wave
	hp = max_hp * 0.1
	GameManager.health_changed.emit(hp, max_hp)
	_last_damage_source_is_boss = false
	# Lock cheats on boss death too
	var pause_menu = get_tree().current_scene.get_node_or_null("PauseMenu")
	if pause_menu and pause_menu.has_method("lock_cheats"):
		pause_menu.lock_cheats()
	# Flash white to show respawn
	$Body.modulate = Color(1, 1, 1, 0.3)
	get_tree().create_timer(0.5).timeout.connect(
		func():
			if is_instance_valid(self):
				$Body.modulate = Color(1, 1, 1)
	)
	# Skip to next wave
	WaveManager.skip_wave()


func _on_fire_timer_timeout():
	can_fire = true

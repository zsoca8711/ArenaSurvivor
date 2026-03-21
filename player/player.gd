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
	"pistol": {"name": "Pistol", "damage": 10, "fire_rate": 0.3, "speed": 800, "spread": 0.0, "bullets": 1, "lifetime": 3.0, "aoe": 0.0, "color": Color(1, 0.9, 0.2), "max_ammo": -1},
	"shotgun": {"name": "Shotgun", "damage": 8, "fire_rate": 0.8, "speed": 600, "spread": 15.0, "bullets": 5, "lifetime": 1.5, "aoe": 0.0, "color": Color(1, 0.6, 0.2), "max_ammo": 60},
	"smg": {"name": "SMG", "damage": 6, "fire_rate": 0.08, "speed": 700, "spread": 5.0, "bullets": 1, "lifetime": 3.0, "aoe": 0.0, "color": Color(0.8, 0.8, 0.2), "max_ammo": 400},
	"rifle": {"name": "Rifle", "damage": 40, "fire_rate": 1.2, "speed": 1200, "spread": 0.0, "bullets": 1, "lifetime": 3.0, "aoe": 0.0, "color": Color(0.3, 0.9, 1.0), "max_ammo": 40},
	"rocket_launcher": {"name": "Rocket Launcher", "damage": 80, "fire_rate": 2.0, "speed": 400, "spread": 0.0, "bullets": 1, "lifetime": 5.0, "aoe": 120.0, "color": Color(1, 0.3, 0.1), "max_ammo": 20},
	"flamethrower": {"name": "Flamethrower", "damage": 3, "fire_rate": 0.03, "speed": 300, "spread": 12.0, "bullets": 1, "lifetime": 0.4, "aoe": 0.0, "color": Color(1, 0.5, 0.0), "max_ammo": 500},
	"minigun": {"name": "Minigun", "damage": 12, "fire_rate": 0.05, "speed": 750, "spread": 8.0, "bullets": 1, "lifetime": 3.0, "aoe": 0.0, "color": Color(0.7, 0.7, 0.7), "max_ammo": 800},
	"wand": {"name": "Wand", "damage": 15, "fire_rate": 0.4, "speed": 600, "spread": 0.0, "bullets": 1, "lifetime": 5.0, "aoe": 0.0, "color": Color(0.1, 0.0, 0.1), "max_ammo": 200, "homing": true},
}

var weapons_owned: Dictionary = {"pistol": -1}  # weapon_id -> ammo (-1 = infinite)
var current_weapon: String = "pistol"
var summon_cooldown: float = 0.0
const SUMMON_COOLDOWN_TIME = 3.0
var minion_scene = preload("res://player/minion.tscn")


func _ready():
	hp = max_hp
	add_to_group("player")


func _physics_process(_delta):
	if is_dead:
		return
	_handle_movement()
	_handle_aim()


func _process(delta):
	if is_dead:
		return
	_handle_shooting()
	_handle_summon(delta)
	_process_contact_damage(delta)


func _handle_summon(delta):
	summon_cooldown -= delta
	if current_weapon == "wand" and Input.is_action_just_pressed("summon") and summon_cooldown <= 0:
		var ammo = weapons_owned.get("wand", 0)
		if ammo == 0:
			return
		if ammo > 0:
			weapons_owned["wand"] -= 5
			if weapons_owned["wand"] < 0:
				weapons_owned["wand"] = 0
		var minion = minion_scene.instantiate()
		minion.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		minion.owner_player = self
		get_tree().current_scene.call_deferred("add_child", minion)
		summon_cooldown = SUMMON_COOLDOWN_TIME


func _input(event):
	if is_dead or get_tree().paused:
		return
	if event.is_action_pressed("weapon_next"):
		_switch_weapon(1)
	elif event.is_action_pressed("weapon_prev"):
		_switch_weapon(-1)


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
	var ammo = weapons_owned[current_weapon]
	# Check ammo (skip for infinite = -1)
	if ammo == 0:
		# Auto-switch to pistol when empty
		current_weapon = "pistol"
		return
	if ammo > 0:
		weapons_owned[current_weapon] -= weapon["bullets"]
		if weapons_owned[current_weapon] <= 0:
			weapons_owned[current_weapon] = 0

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


func add_weapon(weapon_id: String, ammo: int):
	var max_ammo = WEAPONS[weapon_id]["max_ammo"]
	if weapons_owned.has(weapon_id):
		if weapons_owned[weapon_id] >= 0:
			weapons_owned[weapon_id] = mini(weapons_owned[weapon_id] + ammo, max_ammo)
	else:
		weapons_owned[weapon_id] = mini(ammo, max_ammo)
	current_weapon = weapon_id


func add_ammo(amount: int):
	# Add ammo to current weapon if it uses ammo
	if weapons_owned[current_weapon] >= 0:
		var max_a = WEAPONS[current_weapon]["max_ammo"]
		weapons_owned[current_weapon] = mini(weapons_owned[current_weapon] + amount, max_a)
		return
	# Otherwise find first weapon that needs ammo
	for weapon_id in weapons_owned:
		if weapons_owned[weapon_id] >= 0:
			var max_a = WEAPONS[weapon_id]["max_ammo"]
			weapons_owned[weapon_id] = mini(weapons_owned[weapon_id] + amount, max_a)
			return


func get_ammo_text() -> String:
	var ammo = weapons_owned[current_weapon]
	return "INF" if ammo == -1 else str(ammo)


func get_weapon_name() -> String:
	return WEAPONS[current_weapon]["name"]


func _process_contact_damage(delta):
	damage_cooldown -= delta
	if damage_cooldown > 0:
		return
	for body in $Hurtbox.get_overlapping_bodies():
		if body.is_in_group("enemies"):
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
		_die()


func _die():
	is_dead = true
	$Body.modulate = Color(0.5, 0.5, 0.5, 0.5)
	GameManager.on_player_died()


func _on_fire_timer_timeout():
	can_fire = true

extends CharacterBody2D

# Machine Gunner — stationary turret, fast fire, lots of HP
# Only spawns inside bases
@export var max_hp: float = 400.0
@export var contact_damage: float = 5.0
@export var money_reward: int = 300
@export var fire_rate: float = 0.12

var hp: float
var target: Node2D
var fire_timer: float = 0.0
var projectile_scene = preload("res://enemies/enemy_projectile.tscn")

const ATTACK_RANGE = 500.0


func _ready():
	hp = max_hp
	add_to_group("enemies")
	_find_target()
	fire_timer = randf_range(0.5, 2.0)


func _physics_process(_delta):
	# Does NOT move — stationary turret
	if target and is_instance_valid(target):
		var dir = (target.global_position - global_position).normalized()
		rotation = dir.angle()


func _process(delta):
	if not target or not is_instance_valid(target):
		_find_target()
		return
	fire_timer -= delta
	var dist = global_position.distance_to(target.global_position)
	if fire_timer <= 0 and dist <= ATTACK_RANGE:
		_fire()
		fire_timer = fire_rate


func _find_target():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]


func _fire():
	var proj = projectile_scene.instantiate()
	proj.global_position = global_position + Vector2.from_angle(rotation) * 18
	proj.rotation = rotation + randf_range(-0.08, 0.08)  # Slight spread
	proj.damage = 6.0
	proj.speed = 550.0
	get_tree().current_scene.call_deferred("add_child", proj)


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
	call_deferred("queue_free")

extends CharacterBody2D

@export var speed: float = 80.0
@export var max_hp: float = 40.0
@export var contact_damage: float = 5.0
@export var money_reward: int = 100
@export var preferred_distance: float = 400.0
@export var fire_rate: float = 2.0

var hp: float
var target: Node2D
var fire_timer: float = 0.0
var projectile_scene = preload("res://enemies/enemy_projectile.tscn")


func _ready():
	hp = max_hp
	add_to_group("enemies")
	_find_target()
	fire_timer = fire_rate


func _physics_process(delta):
	if target and is_instance_valid(target):
		var to_target = target.global_position - global_position
		var dist = to_target.length()
		var direction = to_target.normalized()
		rotation = direction.angle()

		# Keep distance
		if dist > preferred_distance + 50:
			velocity = direction * speed
		elif dist < preferred_distance - 50:
			velocity = -direction * speed
		else:
			velocity = Vector2.ZERO
		move_and_slide()

		# Shoot
		fire_timer -= delta
		if fire_timer <= 0 and dist < 800:
			_fire()
			fire_timer = fire_rate


func _find_target():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]


func _fire():
	var proj = projectile_scene.instantiate()
	proj.global_position = global_position + Vector2.from_angle(rotation) * 15
	proj.rotation = rotation
	proj.damage = 8.0
	get_tree().current_scene.add_child(proj)


func take_damage(amount: float):
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
	queue_free()

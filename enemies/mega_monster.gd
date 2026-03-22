extends CharacterBody2D

@export var speed: float = 70.0
@export var max_hp: float = 300.0
@export var contact_damage: float = 15.0
@export var money_reward: int = 500
@export var fire_rate: float = 0.15

var hp: float
var target: Node2D
var fire_timer: float = 0.0
var projectile_scene = preload("res://enemies/enemy_projectile.tscn")


func _ready():
	hp = max_hp
	add_to_group("enemies")
	_find_target()
	fire_timer = 1.0


func _physics_process(delta):
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		rotation = direction.angle()

		fire_timer -= delta
		if fire_timer <= 0 and not target.get("in_safe_zone"):
			_fire()
			fire_timer = fire_rate


func _find_target():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]


func _fire():
	var proj = projectile_scene.instantiate()
	proj.global_position = global_position + Vector2.from_angle(rotation) * 30
	var spread = deg_to_rad(randf_range(-10, 10))
	proj.rotation = rotation + spread
	proj.damage = 5.0
	proj.speed = 500.0
	get_tree().current_scene.add_child(proj)


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
	GameManager.spawn_explosion(global_position)
	GameManager.add_money(money_reward)
	GameManager.enemy_killed()
	WaveManager.enemy_died()
	GameManager.try_drop_loot(global_position)
	GameManager.try_drop_loot(global_position)  # Double loot chance
	call_deferred("queue_free")

extends CharacterBody2D

# Giant Tank — brutal HP and damage, very slow
@export var speed: float = 35.0
@export var max_hp: float = 2000.0
@export var contact_damage: float = 60.0
@export var money_reward: int = 2000

var hp: float
var target: Node2D
var projectile_scene = preload("res://enemies/enemy_projectile.tscn")
var fire_timer: float = 0.0
var fire_rate: float = 1.5


func _ready():
	hp = max_hp
	add_to_group("enemies")
	add_to_group("bosses")
	_find_target()
	fire_timer = 2.0


func _physics_process(_delta):
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		rotation = direction.angle()


func _process(delta):
	fire_timer -= delta
	if fire_timer <= 0 and target and is_instance_valid(target):
		_fire()
		fire_timer = fire_rate


func _find_target():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]


func _fire():
	# Fires 3 projectiles in a spread
	for i in 3:
		var proj = projectile_scene.instantiate()
		proj.global_position = global_position + Vector2.from_angle(rotation) * 35
		var spread = deg_to_rad((i - 1) * 15.0)
		proj.rotation = rotation + spread
		proj.damage = 20.0
		proj.speed = 350.0
		proj.from_boss = true
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
	GameManager.try_drop_loot(global_position)
	call_deferred("queue_free")

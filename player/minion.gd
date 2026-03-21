extends CharacterBody2D

@export var speed: float = 180.0
@export var max_hp: float = 20.0
@export var fire_rate: float = 0.8
@export var damage: float = 10.0
@export var follow_distance: float = 80.0
@export var attack_range: float = 400.0

var hp: float
var owner_player: Node2D
var target: Node2D
var fire_timer: float = 0.0
var bullet_scene = preload("res://weapons/bullet.tscn")


func _ready():
	hp = max_hp
	add_to_group("minions")
	fire_timer = randf_range(0, fire_rate)


func _physics_process(_delta):
	if not is_instance_valid(owner_player):
		call_deferred("queue_free")
		return
	_find_target()
	_move()


func _process(delta):
	fire_timer -= delta
	if fire_timer <= 0 and target and is_instance_valid(target):
		_fire()
		fire_timer = fire_rate


func _move():
	var dest: Vector2
	if target and is_instance_valid(target):
		# Move toward enemy but keep some distance
		var to_enemy = target.global_position - global_position
		if to_enemy.length() > attack_range * 0.6:
			dest = target.global_position
		else:
			dest = global_position
	else:
		# Follow player
		dest = owner_player.global_position
	var to_dest = dest - global_position
	if to_dest.length() > follow_distance:
		velocity = to_dest.normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	if velocity.length() > 10:
		rotation = velocity.angle()


func _find_target():
	target = null
	var min_dist = attack_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			target = enemy


func _fire():
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	var dir = (target.global_position - global_position).normalized()
	bullet.rotation = dir.angle()
	bullet.speed = 500.0
	bullet.damage = damage
	bullet.lifetime = 2.0
	bullet.bullet_color = Color(0.3, 0.8, 0.3)
	get_tree().current_scene.call_deferred("add_child", bullet)


func take_damage(amount: float):
	hp -= amount
	$Body.modulate = Color(1, 0.3, 0.3)
	get_tree().create_timer(0.1).timeout.connect(
		func():
			if is_instance_valid(self):
				$Body.modulate = Color(1, 1, 1)
	)
	if hp <= 0:
		call_deferred("queue_free")

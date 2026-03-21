extends Area2D

@export var speed: float = 800.0
@export var damage: float = 10.0
@export var lifetime: float = 3.0
var aoe_radius: float = 0.0
var bullet_color: Color = Color(1, 0.9, 0.2)
var homing: bool = false
var from_boss: bool = false
var homing_target: Node2D = null
var homing_strength: float = 8.0


func _ready():
	$Body.color = bullet_color
	$LifetimeTimer.start(lifetime)
	if homing:
		_find_homing_target()


func _physics_process(delta):
	if homing and homing_target and is_instance_valid(homing_target):
		# Steer toward target
		var desired_dir = (homing_target.global_position - global_position).normalized()
		var current_dir = Vector2.from_angle(rotation)
		var new_dir = current_dir.lerp(desired_dir, homing_strength * delta).normalized()
		rotation = new_dir.angle()
	elif homing and (homing_target == null or not is_instance_valid(homing_target)):
		_find_homing_target()
	position += transform.x * speed * delta


func _find_homing_target():
	var min_dist = 800.0
	homing_target = null
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			homing_target = enemy


func _on_body_entered(body: Node2D):
	if aoe_radius > 0:
		_explode()
	elif body.is_in_group("enemies"):
		body.take_damage(damage, bullet_color)
	elif body.is_in_group("player") and from_boss:
		body._last_damage_source_is_boss = true
		body.take_damage(damage)
			if homing:
				var player = get_tree().get_first_node_in_group("player")
				if player and player.has_method("on_radio_staff_kill"):
					player.on_radio_staff_kill()
	call_deferred("queue_free")


func _explode():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(enemy.global_position) <= aoe_radius:
			enemy.take_damage(damage)
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) <= aoe_radius:
		player.take_damage(damage * 0.3)


func _on_lifetime_timer_timeout():
	call_deferred("queue_free")

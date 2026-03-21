extends Area2D

@export var speed: float = 800.0
@export var damage: float = 10.0
@export var lifetime: float = 3.0
var aoe_radius: float = 0.0
var bullet_color: Color = Color(1, 0.9, 0.2)


func _ready():
	$Body.color = bullet_color
	$LifetimeTimer.start(lifetime)


func _physics_process(delta):
	position += transform.x * speed * delta


func _on_body_entered(body: Node2D):
	if aoe_radius > 0:
		_explode()
	else:
		if body.is_in_group("enemies"):
			body.take_damage(damage)
	queue_free()


func _explode():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(enemy.global_position) <= aoe_radius:
			enemy.take_damage(damage)
	# Self-damage for rockets
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) <= aoe_radius:
		player.take_damage(damage * 0.3)


func _on_lifetime_timer_timeout():
	queue_free()

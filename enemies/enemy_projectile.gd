extends Area2D

@export var speed: float = 400.0
@export var damage: float = 8.0
@export var lifetime: float = 3.0
var from_boss: bool = false


func _ready():
	$LifetimeTimer.start(lifetime)


func _physics_process(delta):
	position += transform.x * speed * delta


func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		if from_boss:
			body._last_damage_source_is_boss = true
		body.take_damage(damage)
	elif body.is_in_group("vehicles"):
		body.take_vehicle_damage(damage)
	call_deferred("queue_free")


func _on_lifetime_timer_timeout():
	call_deferred("queue_free")

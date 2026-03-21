extends Area2D

@export var speed: float = 400.0
@export var damage: float = 8.0
@export var lifetime: float = 3.0


func _ready():
	$LifetimeTimer.start(lifetime)


func _physics_process(delta):
	position += transform.x * speed * delta


func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		body.take_damage(damage)
	call_deferred("queue_free")


func _on_lifetime_timer_timeout():
	queue_free()

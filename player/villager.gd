extends CharacterBody2D

# Villager NPC — runs away from enemies, player must protect them
@export var speed: float = 100.0
@export var max_hp: float = 30.0

var hp: float


func _ready():
	hp = max_hp
	add_to_group("villagers")


func _physics_process(_delta):
	# Run away from nearest enemy
	var nearest_enemy: Node2D = null
	var min_dist = 300.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest_enemy = enemy

	if nearest_enemy:
		var away = (global_position - nearest_enemy.global_position).normalized()
		velocity = away * speed
		rotation = away.angle()
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func take_damage(amount: float, _source_color: Color = Color.WHITE):
	hp -= amount
	$Body.modulate = Color(1, 0.3, 0.3)
	get_tree().create_timer(0.1).timeout.connect(
		func():
			if is_instance_valid(self):
				$Body.modulate = Color(1, 1, 1)
	)
	if hp <= 0:
		call_deferred("queue_free")

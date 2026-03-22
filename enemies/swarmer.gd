extends CharacterBody2D

@export var speed: float = 150.0
@export var max_hp: float = 30.0
@export var contact_damage: float = 10.0
@export var money_reward: int = 50

var hp: float
var target: Node2D


func _ready():
	hp = max_hp
	add_to_group("enemies")
	_find_target()


func _physics_process(_delta):
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		rotation = direction.angle()


func _find_target():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var closest: Node2D = null
		var min_dist = INF
		for p in players:
			var dist = global_position.distance_to(p.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = p
		target = closest


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
	call_deferred("queue_free")

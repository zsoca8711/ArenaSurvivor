extends CharacterBody2D

# Demogorgon — only flamethrower can damage it!
@export var speed: float = 100.0
@export var max_hp: float = 500.0
@export var contact_damage: float = 40.0
@export var money_reward: int = 3000

var hp: float
var target: Node2D


func _ready():
	hp = max_hp
	add_to_group("enemies")
	add_to_group("bosses")
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
		target = players[0]


func take_damage(amount: float, source_color: Color = Color.WHITE):
	# Only flamethrower (orange color) can damage the Demogorgon
	if not _is_flamethrower(source_color):
		return
	hp -= amount
	$Body.modulate = Color(1, 0.3, 0.3)
	get_tree().create_timer(0.05).timeout.connect(
		func():
			if is_instance_valid(self):
				$Body.modulate = Color(1, 1, 1)
	)
	if hp <= 0:
		die()


func _is_flamethrower(color: Color) -> bool:
	# Flamethrower color is Color(1, 0.5, 0.0)
	return color.r > 0.9 and color.g > 0.3 and color.g < 0.7 and color.b < 0.2


func die():
	GameManager.add_money(money_reward)
	GameManager.enemy_killed()
	WaveManager.enemy_died()
	GameManager.try_drop_loot(global_position)
	GameManager.try_drop_loot(global_position)
	GameManager.try_drop_loot(global_position)
	call_deferred("queue_free")

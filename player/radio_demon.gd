extends CharacterBody2D

@export var speed: float = 120.0
@export var max_hp: float = 300.0
@export var follow_distance: float = 100.0
@export var aura_radius: float = 250.0
@export var aura_damage: float = 50.0

var hp: float
var owner_player: Node2D
var hired: bool = false
var aura_active: bool = false
var aura_timer: float = 0.0


func _ready():
	hp = max_hp
	add_to_group("minions")


func _physics_process(_delta):
	if not is_instance_valid(owner_player):
		call_deferred("queue_free")
		return
	# Follow player
	var to_player = owner_player.global_position - global_position
	if to_player.length() > follow_distance:
		velocity = to_player.normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	if velocity.length() > 10:
		rotation = velocity.angle()


func _process(delta):
	if aura_active:
		aura_timer -= delta
		# Green aura: kill everything nearby
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if global_position.distance_to(enemy.global_position) <= aura_radius:
				enemy.take_damage(aura_damage * delta * 3)
		# Visual pulse
		$Body.modulate = Color(0.2, 1.0, 0.2, 0.7 + sin(aura_timer * 10) * 0.3)
		if aura_timer <= 0:
			aura_active = false
			$Body.modulate = Color(1, 1, 1)


func activate_aura():
	aura_active = true
	aura_timer = 5.0
	hired = true


func take_damage(amount: float):
	hp -= amount
	$Body.modulate = Color(1, 0.3, 0.3)
	get_tree().create_timer(0.1).timeout.connect(
		func():
			if is_instance_valid(self):
				if not aura_active:
					$Body.modulate = Color(1, 1, 1)
	)
	if hp <= 0:
		call_deferred("queue_free")

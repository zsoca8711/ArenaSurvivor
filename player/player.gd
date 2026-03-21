extends CharacterBody2D

@export var speed: float = 300.0
@export var max_hp: float = 100.0
@export var fire_rate: float = 0.3
@export var bullet_scene: PackedScene

var hp: float
var can_fire: bool = true
var is_dead: bool = false
var damage_cooldown: float = 0.0
var damage_bonus: float = 0.0

const DAMAGE_COOLDOWN_TIME = 0.5


func _ready():
	hp = max_hp
	add_to_group("player")


func _physics_process(delta):
	if is_dead:
		return
	_handle_movement()
	_handle_aim()
	_process_contact_damage(delta)


func _process(_delta):
	if is_dead:
		return
	_handle_shooting()


func _handle_movement():
	var input = Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")
	velocity = input.normalized() * speed
	move_and_slide()


func _handle_aim():
	look_at(get_global_mouse_position())


func _handle_shooting():
	if Input.is_action_pressed("fire") and can_fire:
		_fire()


func _fire():
	if bullet_scene == null:
		return
	can_fire = false
	var bullet = bullet_scene.instantiate()
	bullet.global_position = $Muzzle.global_position
	bullet.rotation = rotation
	bullet.damage += damage_bonus
	get_tree().current_scene.add_child(bullet)
	$FireTimer.start(fire_rate)


func _process_contact_damage(delta):
	damage_cooldown -= delta
	if damage_cooldown > 0:
		return
	for body in $Hurtbox.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			take_damage(body.contact_damage)
			damage_cooldown = DAMAGE_COOLDOWN_TIME
			break


func take_damage(amount: float):
	if is_dead:
		return
	hp -= amount
	hp = max(hp, 0)
	GameManager.health_changed.emit(hp, max_hp)
	$Body.color = Color(1, 0.3, 0.3)
	get_tree().create_timer(0.1).timeout.connect(
		func():
			if is_instance_valid(self):
				$Body.color = Color(0.2, 0.6, 1.0)
	)
	if hp <= 0:
		_die()


func _die():
	is_dead = true
	$Body.color = Color(0.5, 0.5, 0.5, 0.5)
	GameManager.on_player_died()


func _on_fire_timer_timeout():
	can_fire = true

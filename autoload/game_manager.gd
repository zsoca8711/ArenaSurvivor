extends Node

signal money_changed(amount: int)
signal health_changed(hp: float, max_hp: float)
signal player_died
signal game_over

const ARENA_SIZE = Vector2(3000, 3000)

var money: int = 0
var score: int = 0
var kills: int = 0
var game_active: bool = false


func start_game():
	money = 0
	score = 0
	kills = 0
	game_active = true


func add_money(amount: int):
	money += amount
	score += amount
	money_changed.emit(money)


func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		return true
	return false


func enemy_killed():
	kills += 1


func on_player_died():
	game_active = false
	player_died.emit()
	game_over.emit()


var _pickup_scene = preload("res://loot/pickup.tscn")


func try_drop_loot(pos: Vector2):
	if randf() > 0.25:  # 75% chance of no drop
		return
	var pickup = _pickup_scene.instantiate()
	pickup.global_position = pos
	var roll = randf()
	if roll < 0.25:
		pickup.pickup_type = 0  # HEALTH
	elif roll < 0.45:
		pickup.pickup_type = 1  # AMMO
	elif roll < 0.60:
		pickup.pickup_type = 2  # SPEED_BOOST
	elif roll < 0.75:
		pickup.pickup_type = 3  # DAMAGE_BOOST
	else:
		pickup.pickup_type = 4  # MONEY
	get_tree().current_scene.add_child(pickup)


func reset():
	money = 0
	score = 0
	kills = 0
	game_active = false

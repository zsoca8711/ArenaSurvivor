extends Node

signal money_changed(amount: int)
signal health_changed(hp: float, max_hp: float)
signal player_died
signal game_over

const ARENA_SIZE = Vector2(5000, 5000)

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


func reset():
	money = 0
	score = 0
	kills = 0
	game_active = false

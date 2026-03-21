extends Node2D

@onready var player = $Player
@onready var enemies_container = $Enemies
@onready var shop = $Shop
@onready var pause_menu = $PauseMenu

var swarmer_scene = preload("res://enemies/swarmer.tscn")


func _ready():
	WaveManager.spawn_requested.connect(_on_spawn_requested)
	GameManager.start_game()
	GameManager.health_changed.emit(player.hp, player.max_hp)
	# Short delay before first wave
	get_tree().create_timer(2.0).timeout.connect(
		func(): WaveManager.start_game()
	)


func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		if shop.is_open:
			shop.close()
		elif not pause_menu.is_open:
			pause_menu.open()
		else:
			pause_menu.close()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("open_shop"):
		if pause_menu.is_open:
			return
		if shop.is_open:
			shop.close()
		elif WaveManager.buy_phase_active:
			shop.open()
		get_viewport().set_input_as_handled()


func _on_spawn_requested(position: Vector2):
	var enemy = swarmer_scene.instantiate()
	enemy.global_position = position
	enemies_container.add_child(enemy)

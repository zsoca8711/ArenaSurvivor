extends Node2D

@onready var player = $Player
@onready var enemies_container = $Enemies

var swarmer_scene = preload("res://enemies/swarmer.tscn")


func _ready():
	WaveManager.spawn_requested.connect(_on_spawn_requested)
	GameManager.start_game()
	GameManager.health_changed.emit(player.hp, player.max_hp)
	# Short delay before first wave
	get_tree().create_timer(2.0).timeout.connect(
		func(): WaveManager.start_game()
	)


func _on_spawn_requested(position: Vector2):
	var enemy = swarmer_scene.instantiate()
	enemy.global_position = position
	enemies_container.add_child(enemy)

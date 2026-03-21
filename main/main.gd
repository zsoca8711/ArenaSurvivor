extends Node2D

@onready var player = $Player
@onready var enemies_container = $Enemies

var enemy_scenes = {
	"swarmer": preload("res://enemies/swarmer.tscn"),
	"tank": preload("res://enemies/tank.tscn"),
	"ranged": preload("res://enemies/ranged.tscn"),
	"exploder": preload("res://enemies/exploder.tscn"),
	"mega_monster": preload("res://enemies/mega_monster.tscn"),
}


func _ready():
	WaveManager.spawn_requested.connect(_on_spawn_requested)
	GameManager.start_game()
	GameManager.health_changed.emit(player.hp, player.max_hp)
	# Short delay before first wave
	get_tree().create_timer(2.0).timeout.connect(
		func(): WaveManager.start_game()
	)


func _on_spawn_requested(position: Vector2, enemy_type: String):
	var scene = enemy_scenes.get(enemy_type, enemy_scenes["swarmer"])
	var enemy = scene.instantiate()
	enemy.global_position = position
	enemies_container.add_child(enemy)

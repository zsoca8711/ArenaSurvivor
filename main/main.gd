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

var boss_scenes = {
	"demogorgon": preload("res://enemies/boss_demogorgon.tscn"),
	"giant_tank": preload("res://enemies/boss_giant_tank.tscn"),
}


func _ready():
	WaveManager.spawn_requested.connect(_on_spawn_requested)
	WaveManager.boss_spawn_requested.connect(_on_boss_spawn_requested)
	WaveManager.fortress_activated.connect(_on_fortress_activated)
	GameManager.start_game()
	GameManager.health_changed.emit(player.hp, player.max_hp)
	get_tree().create_timer(2.0).timeout.connect(
		func(): WaveManager.start_game()
	)


func _on_spawn_requested(position: Vector2, enemy_type: String):
	var scene = enemy_scenes.get(enemy_type, enemy_scenes["swarmer"])
	var enemy = scene.instantiate()
	enemy.global_position = position
	enemies_container.add_child(enemy)


func _on_boss_spawn_requested(position: Vector2, boss_type: String):
	var scene = boss_scenes.get(boss_type)
	if scene == null:
		return
	var boss = scene.instantiate()
	boss.global_position = position
	enemies_container.add_child(boss)
	WaveManager.enemies_alive += 1


func _on_fortress_activated():
	var fp = GameManager.FORTRESS_POS
	var fhs = GameManager.FORTRESS_SIZE / 2.0

	var fortress_types = ["swarmer", "tank", "ranged", "exploder", "swarmer", "ranged"]
	for i in 15:
		var type = fortress_types[randi() % fortress_types.size()]
		var scene = enemy_scenes.get(type, enemy_scenes["swarmer"])
		var enemy = scene.instantiate()
		enemy.global_position = fp + Vector2(randf_range(-fhs.x + 40, fhs.x - 40), randf_range(-fhs.y + 40, fhs.y - 40))
		enemy.add_to_group("fortress_enemies")
		enemy.tree_exiting.connect(func(): _on_fortress_enemy_killed())
		enemies_container.add_child(enemy)
		WaveManager.fortress_enemies_alive += 1

	var boss = enemy_scenes["mega_monster"].instantiate()
	boss.global_position = fp
	boss.max_hp = 800.0
	boss.hp = 800.0
	boss.money_reward = 2000
	boss.speed = 40.0
	boss.add_to_group("fortress_enemies")
	boss.tree_exiting.connect(func(): _on_fortress_enemy_killed())
	enemies_container.add_child(boss)
	WaveManager.fortress_enemies_alive += 1


func _on_fortress_enemy_killed():
	WaveManager.fortress_enemy_died()

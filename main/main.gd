extends Node2D

@onready var enemies_container = $Enemies

var player_scene = preload("res://player/player.tscn")

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
	"vecna": preload("res://enemies/boss_vecna.tscn"),
	"mind_flayer": preload("res://enemies/boss_mind_flayer.tscn"),
	"god": preload("res://enemies/boss_god.tscn"),
	"satan": preload("res://enemies/boss_satan.tscn"),
}

var players: Dictionary = {}  # peer_id -> player node


func _ready():
	WaveManager.spawn_requested.connect(_on_spawn_requested)
	WaveManager.boss_spawn_requested.connect(_on_boss_spawn_requested)
	WaveManager.fortress_activated.connect(_on_fortress_activated)
	GameManager.start_game()

	if NetworkManager.is_online:
		_setup_multiplayer()
	else:
		_spawn_local_player()

	get_tree().create_timer(2.0).timeout.connect(
		func(): WaveManager.start_game()
	)


func _spawn_local_player():
	var player = player_scene.instantiate()
	player.global_position = Vector2(5000, 5000)
	add_child(player)
	players[1] = player
	GameManager.health_changed.emit(player.hp, player.max_hp)


func _setup_multiplayer():
	# Spawn local player
	var my_id = multiplayer.get_unique_id()
	_spawn_networked_player(my_id, Vector2(5000, 5000))

	if NetworkManager.is_host:
		# Spawn players for already-connected peers
		var offset = 0
		for peer_id in NetworkManager.connected_peers:
			offset += 1
			_spawn_networked_player(peer_id, Vector2(5000 + offset * 100, 5000))
		# Listen for new connections
		multiplayer.peer_connected.connect(_on_mp_peer_connected)
		multiplayer.peer_disconnected.connect(_on_mp_peer_disconnected)
	else:
		multiplayer.peer_connected.connect(_on_mp_peer_connected)
		multiplayer.peer_disconnected.connect(_on_mp_peer_disconnected)
		# Ask host to tell us about existing players
		_request_players.rpc_id(1)

	var local_player = players.get(my_id)
	if local_player:
		GameManager.health_changed.emit(local_player.hp, local_player.max_hp)


func _spawn_networked_player(peer_id: int, pos: Vector2):
	if players.has(peer_id):
		return
	var player = player_scene.instantiate()
	player.name = "Player_%d" % peer_id
	player.set_multiplayer_authority(peer_id)
	player.global_position = pos
	# Different color for other players
	if peer_id != multiplayer.get_unique_id():
		player.modulate = Color(0.5, 1.0, 0.5)  # Green tint for others
	add_child(player)
	players[peer_id] = player


@rpc("any_peer", "reliable")
func _request_players():
	if not NetworkManager.is_host:
		return
	var sender_id = multiplayer.get_remote_sender_id()
	# Tell the new player about all existing players
	for peer_id in players:
		var pos = players[peer_id].global_position
		_spawn_remote_player.rpc_id(sender_id, peer_id, pos)


@rpc("authority", "reliable")
func _spawn_remote_player(peer_id: int, pos: Vector2):
	_spawn_networked_player(peer_id, pos)


func _on_mp_peer_connected(peer_id: int):
	if NetworkManager.is_host:
		_spawn_networked_player(peer_id, Vector2(5000 + randf_range(-100, 100), 5000 + randf_range(-100, 100)))
		# Tell everyone about the new player
		var pos = players[peer_id].global_position
		_spawn_remote_player.rpc(peer_id, pos)


func _on_mp_peer_disconnected(peer_id: int):
	if players.has(peer_id):
		players[peer_id].queue_free()
		players.erase(peer_id)


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

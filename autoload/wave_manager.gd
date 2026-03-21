extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal buy_phase_started(duration: float)
signal buy_phase_ended
signal spawn_requested(position: Vector2, enemy_type: String)
signal fortress_activated

var current_wave: int = 0
var wave_active: bool = false
var buy_phase_active: bool = false
var enemies_alive: int = 0
var fortress_spawned: bool = false
var fortress_enemies_alive: int = 0
var enemies_to_spawn: int = 0
var wave_timer: float = 0.0
var buy_timer: float = 0.0
var spawn_timer: float = 0.0
var spawn_interval: float = 1.0

const BUY_PHASE_DURATION = 20.0
const WAVE_DURATION = 180.0
const BASE_SPAWN_INTERVAL = 3.0   # seconds between hordes at wave 1
const MIN_SPAWN_INTERVAL = 0.4    # fastest spawn rate
const SPAWN_SPEEDUP = 0.15        # seconds faster per wave
const BONUS_WAVE_INTERVAL = 15
const BONUS_WAVE_MONEY = 1000


func start_game():
	current_wave = 0
	enemies_alive = 0
	_start_next_wave()


func _process(delta):
	if wave_active:
		_process_wave(delta)
	elif buy_phase_active:
		_process_buy_phase(delta)


func _process_wave(delta):
	wave_timer -= delta
	spawn_timer -= delta

	# Continuous spawning for the full 3 minutes
	if wave_timer > 0 and spawn_timer <= 0:
		var base_pos = _random_edge_position()
		var enemy_type = _get_enemy_type()
		# Limit horde size by type
		var max_horde = _get_max_horde(enemy_type)
		var horde_size = randi_range(1, max_horde)
		for i in horde_size:
			var offset = Vector2(randf_range(-80, 80), randf_range(-80, 80))
			spawn_requested.emit(base_pos + offset, enemy_type)
			enemies_alive += 1
		# Spawn interval gets faster each wave
		spawn_interval = max(MIN_SPAWN_INTERVAL, BASE_SPAWN_INTERVAL - current_wave * SPAWN_SPEEDUP)
		spawn_timer = spawn_interval

	# Timer expired — buy phase (enemies stay alive)
	if wave_timer <= 0:
		_wave_expired()


func _wave_expired():
	wave_active = false
	var wave_reward = 100 + current_wave * 50
	GameManager.add_money(wave_reward)
	if current_wave % BONUS_WAVE_INTERVAL == 0:
		GameManager.add_money(BONUS_WAVE_MONEY)
	wave_completed.emit(current_wave)
	_start_buy_phase()


func _start_buy_phase():
	buy_phase_active = true
	buy_timer = BUY_PHASE_DURATION
	buy_phase_started.emit(BUY_PHASE_DURATION)


func _process_buy_phase(delta):
	buy_timer -= delta
	if buy_timer <= 0:
		buy_phase_active = false
		buy_phase_ended.emit()
		_start_next_wave()


func _start_next_wave():
	current_wave += 1
	wave_active = true

	wave_timer = WAVE_DURATION
	spawn_interval = max(MIN_SPAWN_INTERVAL, BASE_SPAWN_INTERVAL - current_wave * SPAWN_SPEEDUP)
	spawn_timer = 0.0

	wave_started.emit(current_wave)

	# Activate fortress at wave 10
	if current_wave == 10 and not fortress_spawned:
		fortress_spawned = true
		fortress_activated.emit()


func enemy_died():
	enemies_alive -= 1


func fortress_enemy_died():
	fortress_enemies_alive -= 1
	if fortress_enemies_alive <= 0 and fortress_spawned:
		GameManager.add_money(5000)
		# Floating text handled by the caller


func get_wave_time_remaining() -> float:
	return max(0, wave_timer)


func get_buy_time_remaining() -> float:
	return max(0, buy_timer)


func _random_edge_position() -> Vector2:
	# Spawn just outside the camera viewport around the player
	var player = _get_player()
	if player == null:
		return Vector2(2500, -50)
	var center = player.global_position
	var margin = 100.0  # Extra distance beyond viewport edge
	var half_w = 960.0 + margin  # Half viewport width + margin
	var half_h = 540.0 + margin  # Half viewport height + margin
	var arena = GameManager.ARENA_SIZE
	var pos: Vector2
	var edge = randi() % 4
	match edge:
		0: pos = Vector2(center.x + randf_range(-half_w, half_w), center.y - half_h)
		1: pos = Vector2(center.x + randf_range(-half_w, half_w), center.y + half_h)
		2: pos = Vector2(center.x - half_w, center.y + randf_range(-half_h, half_h))
		3: pos = Vector2(center.x + half_w, center.y + randf_range(-half_h, half_h))
		_: pos = Vector2(center.x, center.y - half_h)
	pos.x = clamp(pos.x, 0, arena.x)
	pos.y = clamp(pos.y, 0, arena.y)
	return pos


func _get_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null


func _get_enemy_type() -> String:
	if current_wave <= 2:
		return "swarmer"
	elif current_wave <= 4:
		var roll = randf()
		if roll < 0.6:
			return "swarmer"
		elif roll < 0.85:
			return "tank"
		else:
			return "ranged"
	else:
		var roll = randf()
		if roll < 0.35:
			return "swarmer"
		elif roll < 0.55:
			return "tank"
		elif roll < 0.70:
			return "ranged"
		elif roll < 0.85:
			return "exploder"
		else:
			return "mega_monster"


func _get_max_horde(enemy_type: String) -> int:
	match enemy_type:
		"swarmer": return 5 + current_wave
		"tank": return 2
		"ranged": return 2
		"exploder": return 3
		"mega_monster": return 1
	return 3


func skip_wave():
	# Kill all remaining enemies and end wave
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.call_deferred("queue_free")
	enemies_alive = 0
	if wave_active:
		_wave_expired()


func skip_buy_phase():
	if buy_phase_active:
		buy_phase_active = false
		buy_phase_ended.emit()
		_start_next_wave()


func reset():
	current_wave = 0
	wave_active = false
	buy_phase_active = false
	enemies_alive = 0
	enemies_to_spawn = 0
	fortress_spawned = false
	fortress_enemies_alive = 0

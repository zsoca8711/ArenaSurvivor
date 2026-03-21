extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal buy_phase_started(duration: float)
signal buy_phase_ended
signal spawn_requested(position: Vector2)

var current_wave: int = 0
var wave_active: bool = false
var buy_phase_active: bool = false
var enemies_alive: int = 0
var enemies_to_spawn: int = 0
var wave_timer: float = 0.0
var buy_timer: float = 0.0
var spawn_timer: float = 0.0
var spawn_interval: float = 1.0

const BUY_PHASE_DURATION = 20.0
const BASE_WAVE_DURATION = 30.0
const WAVE_DURATION_INCREMENT = 5.0
const BASE_ENEMY_COUNT = 8
const ENEMY_COUNT_INCREMENT = 4
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

	if enemies_to_spawn > 0 and spawn_timer <= 0:
		var pos = _random_edge_position()
		spawn_requested.emit(pos)
		enemies_to_spawn -= 1
		enemies_alive += 1
		spawn_timer = spawn_interval

	# All enemies killed before timer — buy phase reward
	if enemies_alive <= 0 and enemies_to_spawn <= 0:
		_wave_cleared()
		return

	# Timer expired with enemies remaining — next wave stacks on top
	if wave_timer <= 0 and enemies_to_spawn <= 0:
		_start_next_wave()


func _wave_cleared():
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

	var enemy_count = BASE_ENEMY_COUNT + current_wave * ENEMY_COUNT_INCREMENT
	var duration = BASE_WAVE_DURATION + current_wave * WAVE_DURATION_INCREMENT

	enemies_to_spawn = enemy_count
	wave_timer = duration
	spawn_interval = duration / float(enemy_count)
	spawn_timer = 0.0

	wave_started.emit(current_wave)


func enemy_died():
	enemies_alive -= 1


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


func reset():
	current_wave = 0
	wave_active = false
	buy_phase_active = false
	enemies_alive = 0
	enemies_to_spawn = 0

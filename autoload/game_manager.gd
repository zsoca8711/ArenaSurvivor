extends Node

signal money_changed(amount: int)
signal health_changed(hp: float, max_hp: float)
signal player_died
signal game_over
signal enemy_killed_signal

const ARENA_SIZE = Vector2(10000, 10000)
const FORTRESS_POS = Vector2(7500, 7500)
const FORTRESS_SIZE = Vector2(500, 500)

enum Difficulty {EASY, MEDIUM, HARD}
enum MapType {DEFAULT, FOREST, BATTLEFIELD, SNOW}

var difficulty: int = Difficulty.EASY
var map_type: int = MapType.DEFAULT
var story_mode: bool = false
var story_step: int = 0  # 0=find scroll, 1=find treasure, 2=go to safezone, 3=kill 10, 4=won
var money: int = 0
var score: int = 0
var kills: int = 0
var game_active: bool = false


func get_enemy_damage_multiplier() -> float:
	match difficulty:
		Difficulty.MEDIUM: return 1.25
		Difficulty.HARD: return 1.5
	return 1.0


func get_safe_zone_time() -> float:
	match difficulty:
		Difficulty.MEDIUM: return 5.0
		Difficulty.HARD: return 2.0
	return 10.0


const SAVE_PATH = "user://story_save.json"

var _explosion_textures = [
	preload("res://assets/sprites/explosion2.png"),
	preload("res://assets/sprites/explosion3.png"),
	preload("res://assets/sprites/explosion4.png"),
]


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# Clean up to prevent leaks
		if get_tree() and get_tree().current_scene:
			for child in get_tree().current_scene.get_children():
				if child is Sprite2D and child.name.begins_with("@"):
					child.queue_free()


func spawn_explosion(pos: Vector2):
	if not is_instance_valid(get_tree()) or not get_tree().current_scene:
		return
	var spr = Sprite2D.new()
	spr.texture = _explosion_textures[randi() % _explosion_textures.size()]
	spr.global_position = pos
	spr.z_index = 15
	spr.scale = Vector2(0.3, 0.3)
	get_tree().current_scene.call_deferred("add_child", spr)
	var tween = spr.create_tween()
	tween.set_parallel(true)
	tween.tween_property(spr, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_property(spr, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(func():
		if is_instance_valid(spr):
			spr.queue_free()
	)


func save_story():
	var player = get_tree().get_first_node_in_group("player")
	var data = {
		"story_step": story_step,
		"map_type": map_type,
		"money": money,
		"score": score,
		"kills": kills,
		"hp": player.hp if player else 100.0,
		"max_hp": player.max_hp if player else 100.0,
		"weapon": player.current_weapon if player else "pistol",
		"has_telekinetic": player.has_telekinetic if player else false,
		"damage_bonus": player.damage_bonus if player else 0.0,
		"speed": player.speed if player else 200.0,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func load_story() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data == null:
		return false
	story_mode = true
	story_step = int(data.get("story_step", 0))
	map_type = int(data.get("map_type", 0))
	money = int(data.get("money", 0))
	score = int(data.get("score", 0))
	kills = int(data.get("kills", 0))
	return true


func apply_save_to_player(player):
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text = file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data == null:
		return
	player.max_hp = float(data.get("max_hp", 100.0))
	player.hp = float(data.get("hp", 100.0))
	var weapon = data.get("weapon", "")
	if weapon != "":
		player.add_weapon(weapon)
	player.has_telekinetic = data.get("has_telekinetic", false)
	player.damage_bonus = float(data.get("damage_bonus", 0.0))
	player.speed = float(data.get("speed", 200.0))


func delete_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


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
	enemy_killed_signal.emit()


func on_player_died():
	game_active = false
	player_died.emit()
	game_over.emit()


var _pickup_scene = preload("res://loot/pickup.tscn")


func try_drop_loot(pos: Vector2):
	if randf() > 0.25:
		return
	if not is_instance_valid(get_tree()) or not get_tree().current_scene:
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
	get_tree().current_scene.call_deferred("add_child", pickup)


func reset():
	money = 0
	score = 0
	kills = 0
	game_active = false
	story_mode = false
	story_step = 0

# Phase 1: Core Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable single-player prototype with player movement, shooting, one enemy type (Swarmer), wave system, arena with obstacles, HUD, and game over screen.

**Architecture:** Top-down 2D arena shooter in Godot 4 with GDScript. Player (CharacterBody2D) moves with WASD and aims with mouse. Enemies (CharacterBody2D) chase the player. Bullets (Area2D) deal damage on contact. Game state managed through Autoload singletons (GameManager, WaveManager). Placeholder graphics using Polygon2D shapes. Arena boundaries and obstacles created procedurally via code.

**Tech Stack:** Godot 4.2+, GDScript, Godot built-in 2D physics

---

## Prerequisites

- **Godot 4.2+** installed (download from https://godotengine.org/download or `flatpak install flathub org.godotengine.Godot`)
- Git initialized in the project directory

## File Structure

```
crimsonlandclone/
├── .gitignore
├── project.godot
├── autoload/
│   ├── input_setup.gd          # Input mapping (WASD, mouse, abilities)
│   ├── game_manager.gd         # Game state: money, score, kills, HP signals
│   └── wave_manager.gd         # Wave spawning, timer, buy phase
├── player/
│   ├── player.tscn             # CharacterBody2D + Polygon2D + Hurtbox + Camera
│   └── player.gd               # Movement, aiming, shooting, health, contact damage
├── weapons/
│   ├── bullet.tscn             # Area2D + Polygon2D
│   └── bullet.gd               # Forward movement, damage on hit, lifetime
├── enemies/
│   ├── swarmer.tscn            # CharacterBody2D + Polygon2D
│   └── swarmer.gd              # Chase player, take damage, die, reward money
├── map/
│   └── arena.gd                # Procedural boundaries + obstacles + ground
├── ui/
│   ├── hud.gd                  # HP bar, money, wave, timer, kills, center message
│   └── game_over.gd            # Score display, restart button
└── main/
    ├── main.tscn               # Combines all: Arena, Player, Enemies, HUD, GameOver
    └── main.gd                 # Wires WaveManager signals, spawns enemies
```

## Collision Layers

| Layer | Value | Used by |
|-------|-------|---------|
| 1 | 1 | Player (CharacterBody2D) |
| 2 | 2 | Enemies (CharacterBody2D) |
| 3 | 4 | (reserved) |
| 4 | 8 | Walls/Obstacles (StaticBody2D) |

| Node | collision_layer | collision_mask | Effect |
|------|----------------|----------------|--------|
| Player body | 1 | 8 | Collides with walls only |
| Player hurtbox (Area2D) | 0 | 2 | Detects enemy bodies |
| Enemy body | 2 | 8 | Collides with walls only |
| Bullet (Area2D) | 0 | 10 (2+8) | Detects enemies and walls |
| Wall (StaticBody2D) | 8 | 0 | Passive — detected by others |

---

### Task 1: Project Foundation

**Files:**
- Create: `.gitignore`
- Create: `project.godot`
- Create: `autoload/input_setup.gd`

- [ ] **Step 1: Initialize git and create directory structure**

```bash
cd /home/zsoltjanos/work/hobbyprojects/crimsonlandclone
git init
mkdir -p autoload player weapons enemies map ui main
```

- [ ] **Step 2: Write `.gitignore`**

```
# Godot 4
.godot/
```

- [ ] **Step 3: Write `project.godot`**

```ini
; Engine configuration file.
config_version=5

[application]

config/name="Arena Survivor"
run/main_scene="res://main/main.tscn"
config/features=PackedStringArray("4.2", "GL Compatibility")

[autoload]

InputSetup="*res://autoload/input_setup.gd"
GameManager="*res://autoload/game_manager.gd"
WaveManager="*res://autoload/wave_manager.gd"

[display]

window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="canvas_items"

[rendering]

renderer/rendering_method="gl_compatibility"
environment/defaults/default_clear_color=Color(0.1, 0.14, 0.08, 1)
```

- [ ] **Step 4: Write `autoload/input_setup.gd`**

```gdscript
extends Node


func _ready():
	_setup_actions()


func _setup_actions():
	_add_key("move_up", KEY_W)
	_add_key("move_down", KEY_S)
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)
	_add_mouse("fire", MOUSE_BUTTON_LEFT)
	_add_key("open_shop", KEY_E)
	_add_key("ability_1", KEY_U)
	_add_key("ability_2", KEY_I)
	_add_key("ability_3", KEY_O)
	_add_key("ability_4", KEY_P)


func _add_key(action: String, keycode: Key):
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev = InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)


func _add_mouse(action: String, button: MouseButton):
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev = InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
```

- [ ] **Step 5: Verify — open project in Godot editor, confirm no errors in console**

- [ ] **Step 6: Commit**

```bash
git add .gitignore project.godot autoload/input_setup.gd
git commit -m "feat: project foundation with input mapping"
```

---

### Task 2: Game Manager Autoload

**Files:**
- Create: `autoload/game_manager.gd`

- [ ] **Step 1: Write `autoload/game_manager.gd`**

```gdscript
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
```

- [ ] **Step 2: Verify — open project in Godot, confirm autoload is listed and no errors**

- [ ] **Step 3: Commit**

```bash
git add autoload/game_manager.gd
git commit -m "feat: game manager autoload with money, score, signals"
```

---

### Task 3: Bullet System

**Files:**
- Create: `weapons/bullet.gd`
- Create: `weapons/bullet.tscn`

- [ ] **Step 1: Write `weapons/bullet.gd`**

```gdscript
extends Area2D

@export var speed: float = 800.0
@export var damage: float = 10.0
@export var lifetime: float = 3.0


func _ready():
	$LifetimeTimer.start(lifetime)


func _physics_process(delta):
	position += transform.x * speed * delta


func _on_body_entered(body: Node2D):
	if body.is_in_group("enemies"):
		body.take_damage(damage)
	queue_free()


func _on_lifetime_timer_timeout():
	queue_free()
```

- [ ] **Step 2: Write `weapons/bullet.tscn`**

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://weapons/bullet.gd" id="1"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]
size = Vector2(10, 4)

[node name="Bullet" type="Area2D"]
collision_layer = 0
collision_mask = 10
script = ExtResource("1")

[node name="Body" type="Polygon2D" parent="."]
color = Color(1, 0.9, 0.2, 1)
polygon = PackedVector2Array(5, -2, 5, 2, -5, 2, -5, -2)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_1")

[node name="LifetimeTimer" type="Timer" parent="."]
one_shot = true

[connection signal="body_entered" from="." to="." method="_on_body_entered"]
[connection signal="timeout" from="LifetimeTimer" to="." method="_on_lifetime_timer_timeout"]
```

- [ ] **Step 3: Commit**

```bash
git add weapons/bullet.gd weapons/bullet.tscn
git commit -m "feat: bullet with forward movement, damage, lifetime"
```

---

### Task 4: Player Movement & Aiming

**Files:**
- Create: `player/player.gd`
- Create: `player/player.tscn`

- [ ] **Step 1: Write `player/player.gd`**

```gdscript
extends CharacterBody2D

@export var speed: float = 300.0
@export var max_hp: float = 100.0
@export var fire_rate: float = 0.3
@export var bullet_scene: PackedScene

var hp: float
var can_fire: bool = true
var is_dead: bool = false
var damage_cooldown: float = 0.0

const DAMAGE_COOLDOWN_TIME = 0.5


func _ready():
	hp = max_hp
	add_to_group("player")


func _physics_process(delta):
	if is_dead:
		return
	_handle_movement()
	_handle_aim()
	_process_contact_damage(delta)


func _process(_delta):
	if is_dead:
		return
	_handle_shooting()


func _handle_movement():
	var input = Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")
	velocity = input.normalized() * speed
	move_and_slide()


func _handle_aim():
	look_at(get_global_mouse_position())


func _handle_shooting():
	if Input.is_action_pressed("fire") and can_fire:
		_fire()


func _fire():
	if bullet_scene == null:
		return
	can_fire = false
	var bullet = bullet_scene.instantiate()
	bullet.global_position = $Muzzle.global_position
	bullet.rotation = rotation
	get_tree().current_scene.add_child(bullet)
	$FireTimer.start(fire_rate)


func _process_contact_damage(delta):
	damage_cooldown -= delta
	if damage_cooldown > 0:
		return
	for body in $Hurtbox.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			take_damage(body.contact_damage)
			damage_cooldown = DAMAGE_COOLDOWN_TIME
			break


func take_damage(amount: float):
	if is_dead:
		return
	hp -= amount
	hp = max(hp, 0)
	GameManager.health_changed.emit(hp, max_hp)
	$Body.color = Color(1, 0.3, 0.3)
	get_tree().create_timer(0.1).timeout.connect(
		func():
			if is_instance_valid(self):
				$Body.color = Color(0.2, 0.6, 1.0)
	)
	if hp <= 0:
		_die()


func _die():
	is_dead = true
	$Body.color = Color(0.5, 0.5, 0.5, 0.5)
	GameManager.on_player_died()


func _on_fire_timer_timeout():
	can_fire = true
```

- [ ] **Step 2: Write `player/player.tscn`**

```
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://player/player.gd" id="1"]
[ext_resource type="PackedScene" path="res://weapons/bullet.tscn" id="2"]

[sub_resource type="CircleShape2D" id="CircleShape2D_body"]
radius = 16.0

[sub_resource type="CircleShape2D" id="CircleShape2D_hurtbox"]
radius = 20.0

[node name="Player" type="CharacterBody2D"]
collision_layer = 1
collision_mask = 8
script = ExtResource("1")
bullet_scene = ExtResource("2")

[node name="Body" type="Polygon2D" parent="."]
color = Color(0.2, 0.6, 1, 1)
polygon = PackedVector2Array(20, 0, -12, -14, -6, 0, -12, 14)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_body")

[node name="Muzzle" type="Marker2D" parent="."]
position = Vector2(22, 0)

[node name="Hurtbox" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="HurtboxShape" type="CollisionShape2D" parent="Hurtbox"]
shape = SubResource("CircleShape2D_hurtbox")

[node name="FireTimer" type="Timer" parent="."]
one_shot = true

[node name="Camera2D" type="Camera2D" parent="."]

[connection signal="timeout" from="FireTimer" to="." method="_on_fire_timer_timeout"]
```

- [ ] **Step 3: Verify — run player scene (F6 in Godot), confirm WASD movement, mouse aiming, and left-click shooting all work**

- [ ] **Step 4: Commit**

```bash
git add player/player.gd player/player.tscn
git commit -m "feat: player scene with movement, aiming, shooting, health, hurtbox"
```

---

### Task 5: Swarmer Enemy

**Files:**
- Create: `enemies/swarmer.gd`
- Create: `enemies/swarmer.tscn`

- [ ] **Step 1: Write `enemies/swarmer.gd`**

```gdscript
extends CharacterBody2D

@export var speed: float = 150.0
@export var max_hp: float = 30.0
@export var contact_damage: float = 10.0
@export var money_reward: int = 50

var hp: float
var target: Node2D


func _ready():
	hp = max_hp
	add_to_group("enemies")
	_find_target()


func _physics_process(_delta):
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		rotation = direction.angle()


func _find_target():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var closest: Node2D = null
		var min_dist = INF
		for p in players:
			var dist = global_position.distance_to(p.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = p
		target = closest


func take_damage(amount: float):
	hp -= amount
	$Body.color = Color(1, 1, 1)
	get_tree().create_timer(0.05).timeout.connect(
		func():
			if is_instance_valid(self):
				$Body.color = Color(0.9, 0.2, 0.2)
	)
	if hp <= 0:
		die()


func die():
	GameManager.add_money(money_reward)
	GameManager.enemy_killed()
	WaveManager.enemy_died()
	queue_free()
```

- [ ] **Step 2: Write `enemies/swarmer.tscn`**

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://enemies/swarmer.gd" id="1"]

[sub_resource type="CircleShape2D" id="CircleShape2D_1"]
radius = 10.0

[node name="Swarmer" type="CharacterBody2D"]
collision_layer = 2
collision_mask = 8
script = ExtResource("1")

[node name="Body" type="Polygon2D" parent="."]
color = Color(0.9, 0.2, 0.2, 1)
polygon = PackedVector2Array(10, 0, -7, -8, -4, 0, -7, 8)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_1")
```

- [ ] **Step 3: Commit**

```bash
git add enemies/swarmer.gd enemies/swarmer.tscn
git commit -m "feat: swarmer enemy with chase AI, damage, death reward"
```

---

### Task 6: Wave Manager

**Files:**
- Create: `autoload/wave_manager.gd`

- [ ] **Step 1: Write `autoload/wave_manager.gd`**

```gdscript
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
```

- [ ] **Step 2: Verify — open project in Godot, confirm all 3 autoloads listed and no errors**

- [ ] **Step 3: Commit**

```bash
git add autoload/wave_manager.gd
git commit -m "feat: wave manager with spawn signals, buy phase, wave stacking"
```

---

### Task 7: Arena Map

**Files:**
- Create: `map/arena.gd`

- [ ] **Step 1: Write `map/arena.gd`**

```gdscript
extends Node2D

const WALL_THICKNESS = 50.0
const WALL_COLOR = Color(0.35, 0.3, 0.25)
const GROUND_COLOR = Color(0.18, 0.22, 0.12)
const OBSTACLE_COLOR = Color(0.45, 0.42, 0.35)


func _ready():
	_create_ground()
	_create_boundaries()
	_create_obstacles()


func _create_ground():
	var ground = ColorRect.new()
	ground.color = GROUND_COLOR
	ground.size = GameManager.ARENA_SIZE
	ground.z_index = -10
	add_child(ground)


func _create_boundaries():
	var hw = WALL_THICKNESS / 2.0
	var ax = GameManager.ARENA_SIZE.x
	var ay = GameManager.ARENA_SIZE.y
	_create_wall(Vector2(ax / 2, -hw), Vector2(ax + WALL_THICKNESS * 2, WALL_THICKNESS))
	_create_wall(Vector2(ax / 2, ay + hw), Vector2(ax + WALL_THICKNESS * 2, WALL_THICKNESS))
	_create_wall(Vector2(-hw, ay / 2), Vector2(WALL_THICKNESS, ay + WALL_THICKNESS * 2))
	_create_wall(Vector2(ax + hw, ay / 2), Vector2(WALL_THICKNESS, ay + WALL_THICKNESS * 2))


func _create_wall(pos: Vector2, size: Vector2):
	var wall = StaticBody2D.new()
	wall.collision_layer = 8
	wall.collision_mask = 0
	wall.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	wall.add_child(shape)
	var visual = ColorRect.new()
	visual.color = WALL_COLOR
	visual.size = size
	visual.position = -size / 2
	wall.add_child(visual)
	add_child(wall)


func _create_obstacles():
	# Central rock formation
	_create_obstacle(Vector2(2500, 2500), Vector2(200, 200))
	# Corner clusters
	_create_obstacle(Vector2(1000, 1000), Vector2(150, 300))
	_create_obstacle(Vector2(4000, 1000), Vector2(300, 150))
	_create_obstacle(Vector2(1000, 4000), Vector2(250, 100))
	_create_obstacle(Vector2(4000, 4000), Vector2(100, 250))
	# Long walls creating corridors
	_create_obstacle(Vector2(2500, 1500), Vector2(800, 50))
	_create_obstacle(Vector2(2500, 3500), Vector2(800, 50))
	_create_obstacle(Vector2(1500, 2500), Vector2(50, 800))
	_create_obstacle(Vector2(3500, 2500), Vector2(50, 800))


func _create_obstacle(pos: Vector2, size: Vector2):
	var obstacle = StaticBody2D.new()
	obstacle.collision_layer = 8
	obstacle.collision_mask = 0
	obstacle.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	obstacle.add_child(shape)
	var visual = ColorRect.new()
	visual.color = OBSTACLE_COLOR
	visual.size = size
	visual.position = -size / 2
	obstacle.add_child(visual)
	add_child(obstacle)
```

- [ ] **Step 2: Commit**

```bash
git add map/arena.gd
git commit -m "feat: arena with boundaries, ground, and obstacle layout"
```

---

### Task 8: HUD

**Files:**
- Create: `ui/hud.gd`

- [ ] **Step 1: Write `ui/hud.gd`**

```gdscript
extends CanvasLayer

var health_bar: ProgressBar
var health_label: Label
var money_label: Label
var wave_label: Label
var timer_label: Label
var kills_label: Label
var center_message: Label
var _center_msg_tween: Tween


func _ready():
	_build_ui()
	_connect_signals()
	center_message.visible = false


func _build_ui():
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 30)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)

	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(200, 25)
	health_bar.value = 100
	health_bar.show_percentage = false
	var fg = StyleBoxFlat.new()
	fg.bg_color = Color(0.8, 0.1, 0.1)
	health_bar.add_theme_stylebox_override("fill", fg)
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.3, 0.1, 0.1)
	health_bar.add_theme_stylebox_override("background", bg)
	hbox.add_child(health_bar)

	health_label = _make_label("HP: 100/100")
	hbox.add_child(health_label)

	money_label = _make_label("$0", Color(1, 0.85, 0))
	hbox.add_child(money_label)

	wave_label = _make_label("Wave 0")
	hbox.add_child(wave_label)

	timer_label = _make_label("Time: 0:00")
	hbox.add_child(timer_label)

	kills_label = _make_label("Kills: 0")
	hbox.add_child(kills_label)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	center_message = Label.new()
	center_message.add_theme_font_size_override("font_size", 48)
	center_message.add_theme_color_override("font_color", Color(1, 1, 0))
	center.add_child(center_message)


func _make_label(text: String, color: Color = Color.WHITE) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	return label


func _connect_signals():
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.health_changed.connect(_on_health_changed)
	WaveManager.wave_started.connect(_on_wave_started)
	WaveManager.wave_completed.connect(_on_wave_completed)
	WaveManager.buy_phase_started.connect(_on_buy_phase_started)


func _process(_delta):
	if WaveManager.wave_active:
		var t = WaveManager.get_wave_time_remaining()
		timer_label.text = "Time: %d:%02d" % [int(t) / 60, int(t) % 60]
	elif WaveManager.buy_phase_active:
		var t = WaveManager.get_buy_time_remaining()
		timer_label.text = "Shop: %d" % ceili(t)
	kills_label.text = "Kills: %d" % GameManager.kills


func _on_money_changed(amount: int):
	money_label.text = "$%d" % amount


func _on_health_changed(hp: float, max_hp: float):
	health_bar.value = (hp / max_hp) * 100.0
	health_label.text = "HP: %d/%d" % [int(hp), int(max_hp)]


func _on_wave_started(wave_number: int):
	wave_label.text = "Wave %d" % wave_number
	_show_center_message("Wave %d" % wave_number, 2.0)


func _on_wave_completed(wave_number: int):
	_show_center_message("Wave %d Cleared!" % wave_number, 2.0)


func _on_buy_phase_started(_duration: float):
	_show_center_message("Buy Phase", 3.0)


func _show_center_message(text: String, duration: float):
	if _center_msg_tween and _center_msg_tween.is_valid():
		_center_msg_tween.kill()
	center_message.text = text
	center_message.visible = true
	_center_msg_tween = create_tween()
	_center_msg_tween.tween_callback(func(): center_message.visible = false).set_delay(duration)
```

- [ ] **Step 2: Commit**

```bash
git add ui/hud.gd
git commit -m "feat: HUD with health bar, money, wave, timer, center messages"
```

---

### Task 9: Game Over Screen

**Files:**
- Create: `ui/game_over.gd`

- [ ] **Step 1: Write `ui/game_over.gd`**

```gdscript
extends CanvasLayer

var score_label: Label
var kills_label: Label
var waves_label: Label
var restart_button: Button


func _ready():
	_build_ui()
	visible = false
	GameManager.game_over.connect(_on_game_over)


func _build_ui():
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	var title = Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	vbox.add_child(title)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	vbox.add_child(score_label)

	kills_label = Label.new()
	kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kills_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(kills_label)

	waves_label = Label.new()
	waves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	waves_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(waves_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	restart_button = Button.new()
	restart_button.text = "Play Again"
	restart_button.custom_minimum_size = Vector2(200, 50)
	restart_button.pressed.connect(_on_restart)
	vbox.add_child(restart_button)


func _on_game_over():
	score_label.text = "Score: $%d" % GameManager.score
	kills_label.text = "Kills: %d" % GameManager.kills
	waves_label.text = "Waves survived: %d" % WaveManager.current_wave
	visible = true
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_restart():
	get_tree().paused = false
	visible = false
	GameManager.reset()
	WaveManager.reset()
	get_tree().reload_current_scene()
```

- [ ] **Step 2: Commit**

```bash
git add ui/game_over.gd
git commit -m "feat: game over screen with score, restart, pause"
```

---

### Task 10: Main Scene Integration

**Files:**
- Create: `main/main.gd`
- Create: `main/main.tscn`

- [ ] **Step 1: Write `main/main.gd`**

```gdscript
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
```

- [ ] **Step 2: Write `main/main.tscn`**

```
[gd_scene load_steps=6 format=3]

[ext_resource type="Script" path="res://main/main.gd" id="1"]
[ext_resource type="PackedScene" path="res://player/player.tscn" id="2"]
[ext_resource type="Script" path="res://map/arena.gd" id="3"]
[ext_resource type="Script" path="res://ui/hud.gd" id="4"]
[ext_resource type="Script" path="res://ui/game_over.gd" id="5"]

[node name="Main" type="Node2D"]
script = ExtResource("1")

[node name="Arena" type="Node2D" parent="."]
script = ExtResource("3")

[node name="Player" parent="." instance=ExtResource("2")]
position = Vector2(2500, 2500)

[node name="Enemies" type="Node2D" parent="."]

[node name="HUD" type="CanvasLayer" parent="."]
script = ExtResource("4")

[node name="GameOver" type="CanvasLayer" parent="."]
script = ExtResource("5")
```

- [ ] **Step 3: Verify — run the game (F5 in Godot)**

Test the full game loop:
1. Player spawns at center of arena (2500, 2500)
2. WASD moves player, player rotates toward mouse
3. Left-click shoots yellow bullets
4. After 2 seconds, Wave 1 starts — "Wave 1" message appears
5. Red swarmer enemies spawn from edges, chase player
6. Bullets kill swarmers (3 hits at 10 damage vs 30 HP)
7. Swarmers deal contact damage (HP bar decreases)
8. Killing all swarmers before timer → "Wave 1 Cleared!" + buy phase
9. Failing to kill in time → Wave 2 stacks on top
10. Player reaches 0 HP → "GAME OVER" screen with score
11. "Play Again" button restarts the game
12. Player collides with walls/obstacles but walks through enemies

- [ ] **Step 4: Commit**

```bash
git add main/main.gd main/main.tscn
git commit -m "feat: main scene integration — complete game loop"
```

---

### Task 11: Playtest & Tune

- [ ] **Step 1: Play through at least 5 waves, note any issues**

Common things to check:
- Enemy spawn positions (should be off-screen)
- Wave timer feels right (not too fast/slow)
- Bullet damage vs enemy HP balance
- Contact damage frequency (0.5s cooldown)
- Camera follows player smoothly
- Obstacles block movement for both player and enemies
- Bullets destroyed on wall hit
- Multiple waves stacking when timer expires

- [ ] **Step 2: Adjust balance constants if needed**

Key tuning values:
- `player.gd`: `speed=300`, `max_hp=100`, `fire_rate=0.3`
- `bullet.gd`: `speed=800`, `damage=10`
- `swarmer.gd`: `speed=150`, `max_hp=30`, `contact_damage=10`
- `wave_manager.gd`: `BASE_ENEMY_COUNT=8`, `ENEMY_COUNT_INCREMENT=4`, `BASE_WAVE_DURATION=30`

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "tune: balance adjustments after playtest"
```

---

## Future Phases

### Phase 2: Full Combat System
- All 7 weapon types (shotgun, SMG, rifle, rocket launcher, flamethrower, minigun)
- All 6 ability types (dash, AOE, shield, mine, freeze, teleport)
- All 5 enemy types (swarmer, tank, ranged, exploder, mega monster)
- Boss enemies every 5 waves
- Loot drops (health, ammo, speed boost, damage boost, money)

### Phase 3: Economy & Progression
- Shop UI (Counter-Strike style, E key)
- Weapon purchasing and upgrades
- Ability purchasing and cooldown upgrades
- Player classes (light/normal/heavy) with selection screen
- Color assignment (blue, red, yellow, purple)
- Local leaderboard (score = total money earned)

### Phase 4: LAN Multiplayer
- Host-client networking (Godot ENet)
- Lobby system (create room / enter IP)
- Player synchronization (position, rotation, shooting)
- Enemy sync (host-authoritative spawning)
- Shared economy and individual inventories
- Death/respawn (wait until wave end, weapons drop at death location)
- PvP mode
- Difficulty scaling by player count

### Phase 5: Audio & Polish
- Music from Spotify playlist (need to source/license appropriate tracks)
- Weapon sound effects
- Enemy sound effects
- UI sounds
- Visual effects (muzzle flash, explosions, death particles)
- Screen shake
- Balance pass across all systems

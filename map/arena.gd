extends Node2D

const TILE = 64
const WALL_THICKNESS = 50.0

# Textures
var grass1 = preload("res://assets/sprites/tile_grass1.png")
var grass2 = preload("res://assets/sprites/tile_grass2.png")
var sand1 = preload("res://assets/sprites/tile_sand1.png")
var sand2 = preload("res://assets/sprites/tile_sand2.png")
var road_n = preload("res://assets/sprites/road_north.png")
var road_e = preload("res://assets/sprites/road_east.png")
var road_x = preload("res://assets/sprites/road_crossing.png")
var road_cll = preload("res://assets/sprites/road_corner_ll.png")
var road_clr = preload("res://assets/sprites/road_corner_lr.png")
var road_cul = preload("res://assets/sprites/road_corner_ul.png")
var road_cur = preload("res://assets/sprites/road_corner_ur.png")
var road_sn = preload("res://assets/sprites/road_split_n.png")
var road_ss = preload("res://assets/sprites/road_split_s.png")
var road_se = preload("res://assets/sprites/road_split_e.png")
var road_sw = preload("res://assets/sprites/road_split_w.png")
var tree_large = preload("res://assets/sprites/tree_large.png")
var tree_small = preload("res://assets/sprites/tree_small.png")
var tree_br_large = preload("res://assets/sprites/tree_brown_large.png")
var tree_br_small = preload("res://assets/sprites/tree_brown_small.png")
var tree_twigs = preload("res://assets/sprites/tree_twigs.png")
var sandbag_tex = preload("res://assets/sprites/sandbag.png")
var sandbag_beige = preload("res://assets/sprites/sandbag_beige.png")
var barricade_tex = preload("res://assets/sprites/barricade.png")
var barricade_wood = preload("res://assets/sprites/barricade_wood.png")
var crate_tex = preload("res://assets/sprites/crate.png")
var crate_metal = preload("res://assets/sprites/crate_metal.png")
var barrel_tex = preload("res://assets/sprites/barrel.png")
var barrel_red = preload("res://assets/sprites/barrel_red.png")
var barrel_green = preload("res://assets/sprites/barrel_green.png")
var fence_tex = preload("res://assets/sprites/fence.png")
var fence_yellow = preload("res://assets/sprites/fence_yellow.png")
var oil_large = preload("res://assets/sprites/oil_large.png")
var oil_small = preload("res://assets/sprites/oil_small.png")
var machine_gunner_scene = preload("res://enemies/machine_gunner.tscn")
var safe_zone_scene = preload("res://map/safe_zone.tscn")
var sandbag_open = preload("res://assets/sprites/sandbag_open.png")
var wire_crooked = preload("res://assets/sprites/wire_crooked.png")
var wire_straight = preload("res://assets/sprites/wire_straight.png")
var tracks_double = preload("res://assets/sprites/tracks_double.png")
var tracks_large = preload("res://assets/sprites/tracks_large.png")
var tracks_small = preload("res://assets/sprites/tracks_small.png")
var barrel_rust = preload("res://assets/sprites/barrel_rust.png")
var barrel_black = preload("res://assets/sprites/barrel_black.png")
var crate_metal_side = preload("res://assets/sprites/crate_metal_side.png")
var crate_wood_side = preload("res://assets/sprites/crate_wood_side.png")
var special_barrel1 = preload("res://assets/sprites/special_barrel1.png")
var special_barrel2 = preload("res://assets/sprites/special_barrel2.png")
var special_barrel3 = preload("res://assets/sprites/special_barrel3.png")
var tree_leaf = preload("res://assets/sprites/tree_leaf.png")
var tree_brown_leaf = preload("res://assets/sprites/tree_brown_leaf.png")

# Road grid positions
var h_roads = [1500, 3500, 5000, 6500, 8500]
var v_roads = [1500, 3500, 5000, 6500, 8500]


func _ready():
	_create_ground()
	_create_boundaries()
	_create_road_network()
	_create_roadside_trees()
	_create_scattered_decorations()
	_create_map_extras()
	_create_bases()
	_create_safe_zones()
	_create_fortress()


# --- GROUND ---
func _create_ground():
	var ground = TextureRect.new()
	if GameManager.map_type == GameManager.MapType.SNOW:
		# White background for snow
		var bg = ColorRect.new()
		bg.color = Color(0.92, 0.93, 0.95)
		bg.size = GameManager.ARENA_SIZE
		bg.z_index = -10
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		return
	ground.texture = grass1
	ground.stretch_mode = TextureRect.STRETCH_TILE
	ground.size = GameManager.ARENA_SIZE
	ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ground.z_index = -10
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	# Sandy patches (skip for snow)
	for i in 40:
		var patch = Sprite2D.new()
		patch.texture = [sand1, sand2][randi() % 2]
		patch.position = Vector2(randf_range(100, 9900), randf_range(100, 9900))
		patch.scale = Vector2(2, 2)
		patch.z_index = -9
		add_child(patch)


# --- BOUNDARIES ---
func _create_boundaries():
	var ax = GameManager.ARENA_SIZE.x
	var ay = GameManager.ARENA_SIZE.y
	var hw = WALL_THICKNESS / 2.0
	_create_wall(Vector2(ax/2, -hw), Vector2(ax + WALL_THICKNESS*2, WALL_THICKNESS))
	_create_wall(Vector2(ax/2, ay+hw), Vector2(ax + WALL_THICKNESS*2, WALL_THICKNESS))
	_create_wall(Vector2(-hw, ay/2), Vector2(WALL_THICKNESS, ay + WALL_THICKNESS*2))
	_create_wall(Vector2(ax+hw, ay/2), Vector2(WALL_THICKNESS, ay + WALL_THICKNESS*2))


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
	visual.color = Color(0.3, 0.25, 0.2)
	visual.size = size
	visual.position = -size / 2
	wall.add_child(visual)
	add_child(wall)


# --- ROAD NETWORK ---
func _create_road_network():
	var road_set = {}  # track which tiles have roads: "x,y" -> type

	# Mark crossings
	for hx in h_roads:
		for vy in v_roads:
			road_set[_key(hx, vy)] = "crossing"

	# Place horizontal road tiles
	for ry in h_roads:
		var x = TILE / 2
		while x < GameManager.ARENA_SIZE.x:
			var k = _key(x, ry)
			if not road_set.has(k):
				_place_tile(road_e, Vector2(x, ry))
			else:
				_place_tile(road_x, Vector2(x, ry))
			x += TILE

	# Place vertical road tiles
	for rx in v_roads:
		var y = TILE / 2
		while y < GameManager.ARENA_SIZE.y:
			var k = _key(rx, y)
			if not road_set.has(k):
				_place_tile(road_n, Vector2(rx, y))
			y += TILE


func _place_tile(tex: Texture2D, pos: Vector2):
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = pos
	spr.z_index = -8
	add_child(spr)


func _key(x: float, y: float) -> String:
	return "%d,%d" % [snappedi(int(x), TILE), snappedi(int(y), TILE)]


# --- ROADSIDE TREES ---
func _create_roadside_trees():
	var tree_textures = [tree_large, tree_small, tree_br_large, tree_br_small, tree_twigs]

	# Along horizontal roads
	for ry in h_roads:
		var x = 100.0
		while x < GameManager.ARENA_SIZE.x - 100:
			if randf() < 0.3:
				_place_tree(tree_textures[randi() % tree_textures.size()],
					Vector2(x, ry + 60 * (1 if randf() > 0.5 else -1) + randf_range(-15, 15)))
			x += randf_range(60, 150)

	# Along vertical roads
	for rx in v_roads:
		var y = 100.0
		while y < GameManager.ARENA_SIZE.y - 100:
			if randf() < 0.3:
				_place_tree(tree_textures[randi() % tree_textures.size()],
					Vector2(rx + 60 * (1 if randf() > 0.5 else -1) + randf_range(-15, 15), y))
			y += randf_range(60, 150)


func _place_tree(tex: Texture2D, pos: Vector2):
	# Trees are visual only (no collision) for gameplay flow
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = pos
	spr.z_index = 1
	add_child(spr)


# --- SCATTERED DECORATIONS ---
func _create_scattered_decorations():
	var ax = GameManager.ARENA_SIZE.x
	var ay = GameManager.ARENA_SIZE.y
	var fp = GameManager.FORTRESS_POS
	var fs = GameManager.FORTRESS_SIZE

	# Tree clusters (50 clusters across the map)
	for i in 50:
		var center = _random_pos_outside_fortress()
		var count = randi_range(3, 7)
		for j in count:
			var offset = Vector2(randf_range(-80, 80), randf_range(-80, 80))
			var tex = [tree_large, tree_small, tree_br_large, tree_br_small][randi() % 4]
			_place_tree(tex, center + offset)

	# Oil spills (30)
	for i in 30:
		var spr = Sprite2D.new()
		spr.texture = [oil_large, oil_small][randi() % 2]
		spr.position = _random_pos_outside_fortress()
		spr.z_index = -7
		add_child(spr)

	# Barrel clusters (25)
	for i in 25:
		var center = _random_pos_outside_fortress()
		for j in randi_range(1, 4):
			var tex = [barrel_tex, barrel_red, barrel_green][randi() % 3]
			_place_obstacle(center + Vector2(randf_range(-20, 20), randf_range(-20, 20)), tex, Vector2(22, 22))

	# Crate clusters (20)
	for i in 20:
		var center = _random_pos_outside_fortress()
		for j in randi_range(1, 3):
			var tex = [crate_tex, crate_metal][randi() % 2]
			_place_obstacle(center + Vector2(randf_range(-25, 25), randf_range(-25, 25)), tex, Vector2(36, 36))

	# Sandbag walls (20 small walls scattered)
	for i in 20:
		var start = _random_pos_outside_fortress()
		var horizontal = randf() > 0.5
		for j in randi_range(2, 6):
			var offset = Vector2(j * 38, 0) if horizontal else Vector2(0, j * 26)
			var tex = [sandbag_tex, sandbag_beige, sandbag_open][randi() % 3]
			_place_obstacle(start + offset, tex, Vector2(36, 22))

	# Wire fences (30 scattered)
	for i in 30:
		var pos = _random_pos_outside_fortress()
		var tex = [wire_crooked, wire_straight][randi() % 2]
		_place_obstacle(pos, tex, Vector2(40, 10))

	# Tank tracks on ground (40 — decoration only)
	for i in 40:
		var spr = Sprite2D.new()
		spr.texture = [tracks_double, tracks_large, tracks_small][randi() % 3]
		spr.position = _random_pos_outside_fortress()
		spr.rotation = randf() * TAU
		spr.z_index = -7
		add_child(spr)

	# Rust/black barrel clusters (20)
	for i in 20:
		var center = _random_pos_outside_fortress()
		for j in randi_range(1, 3):
			var tex = [barrel_rust, barrel_black][randi() % 2]
			_place_obstacle(center + Vector2(randf_range(-18, 18), randf_range(-18, 18)), tex, Vector2(20, 20))

	# Side crates (15)
	for i in 15:
		var tex = [crate_wood_side, crate_metal_side][randi() % 2]
		_place_obstacle(_random_pos_outside_fortress(), tex, Vector2(34, 34))

	# Special barrels / destroyed vehicles (20)
	for i in 20:
		var tex = [special_barrel1, special_barrel2, special_barrel3][randi() % 3]
		var spr = Sprite2D.new()
		spr.texture = tex
		spr.position = _random_pos_outside_fortress()
		spr.rotation = randf() * TAU
		spr.z_index = 0
		add_child(spr)

	# Leaf piles (25 — decoration)
	for i in 25:
		var spr = Sprite2D.new()
		spr.texture = [tree_leaf, tree_brown_leaf][randi() % 2]
		spr.position = _random_pos_outside_fortress()
		spr.z_index = -6
		add_child(spr)


# --- MAP-SPECIFIC EXTRAS ---
func _create_map_extras():
	match GameManager.map_type:
		GameManager.MapType.FOREST:
			_create_forest_extras()
		GameManager.MapType.BATTLEFIELD:
			_create_battlefield_extras()
		GameManager.MapType.SNOW:
			pass  # Snow is just white, no extras needed


func _create_forest_extras():
	# +40% more trees and bushes
	var tree_textures = [tree_large, tree_small, tree_br_large, tree_br_small, tree_twigs, tree_leaf, tree_brown_leaf]
	for i in 80:
		var center = _random_pos_outside_fortress()
		var count = randi_range(4, 10)
		for j in count:
			var offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
			var tex = tree_textures[randi() % tree_textures.size()]
			_place_tree(tex, center + offset)

	# Extra roadside bushes
	for ry in h_roads:
		var x = 50.0
		while x < GameManager.ARENA_SIZE.x - 50:
			if randf() < 0.5:
				var tex = tree_textures[randi() % tree_textures.size()]
				var side = 50 * (1 if randf() > 0.5 else -1)
				_place_tree(tex, Vector2(x, ry + side + randf_range(-20, 20)))
			x += randf_range(40, 100)
	for rx in v_roads:
		var y = 50.0
		while y < GameManager.ARENA_SIZE.y - 50:
			if randf() < 0.5:
				var tex = tree_textures[randi() % tree_textures.size()]
				var side = 50 * (1 if randf() > 0.5 else -1)
				_place_tree(tex, Vector2(rx + side + randf_range(-20, 20), y))
			y += randf_range(40, 100)


func _create_battlefield_extras():
	# Lots of tank structures, wire, sandbags, tracks
	# Extra wire fences (50 more)
	for i in 50:
		var tex = [wire_crooked, wire_straight][randi() % 2]
		_place_obstacle(_random_pos_outside_fortress(), tex, Vector2(40, 10))

	# Extra sandbag fortifications (30)
	for i in 30:
		var start = _random_pos_outside_fortress()
		var horizontal = randf() > 0.5
		for j in randi_range(3, 8):
			var offset = Vector2(j * 38, 0) if horizontal else Vector2(0, j * 26)
			var tex = [sandbag_tex, sandbag_beige, sandbag_open][randi() % 3]
			_place_obstacle(start + offset, tex, Vector2(36, 22))

	# Tons of tank tracks (80 more)
	for i in 80:
		var spr = Sprite2D.new()
		spr.texture = [tracks_double, tracks_large, tracks_small][randi() % 3]
		spr.position = _random_pos_outside_fortress()
		spr.rotation = randf() * TAU
		spr.z_index = -7
		add_child(spr)

	# Extra barrel clusters (30)
	for i in 30:
		var center = _random_pos_outside_fortress()
		for j in randi_range(2, 5):
			var tex = [barrel_tex, barrel_red, barrel_rust, barrel_black, barrel_green][randi() % 5]
			_place_obstacle(center + Vector2(randf_range(-25, 25), randf_range(-25, 25)), tex, Vector2(22, 22))

	# Extra crates (25)
	for i in 25:
		var tex = [crate_tex, crate_metal, crate_wood_side, crate_metal_side][randi() % 4]
		_place_obstacle(_random_pos_outside_fortress(), tex, Vector2(34, 34))

	# Extra special barrels / wreckage (30)
	for i in 30:
		var spr = Sprite2D.new()
		spr.texture = [special_barrel1, special_barrel2, special_barrel3][randi() % 3]
		spr.position = _random_pos_outside_fortress()
		spr.rotation = randf() * TAU
		spr.z_index = 0
		add_child(spr)

	# Extra barricades (20)
	for i in 20:
		var tex = [barricade_tex, barricade_wood][randi() % 2]
		_place_obstacle(_random_pos_outside_fortress(), tex, Vector2(50, 50))


func _random_pos_outside_fortress() -> Vector2:
	var fp = GameManager.FORTRESS_POS
	var fhs = GameManager.FORTRESS_SIZE / 2.0
	var pos: Vector2
	for attempt in 20:
		pos = Vector2(randf_range(200, 9800), randf_range(200, 9800))
		if abs(pos.x - fp.x) > fhs.x + 100 or abs(pos.y - fp.y) > fhs.y + 100:
			return pos
	return pos


func _place_obstacle(pos: Vector2, tex: Texture2D, col_size: Vector2):
	var body = StaticBody2D.new()
	body.collision_layer = 8
	body.collision_mask = 0
	body.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = col_size
	shape.shape = rect
	body.add_child(shape)
	var spr = Sprite2D.new()
	spr.texture = tex
	body.add_child(spr)
	add_child(body)


# --- BASES (small outposts at road intersections) ---
func _create_bases():
	# Place bases at some road intersections (not all, and not at fortress or center)
	var base_positions = []
	var fp = GameManager.FORTRESS_POS
	var center = GameManager.ARENA_SIZE / 2.0

	for hx in h_roads:
		for vy in v_roads:
			var pos = Vector2(hx, vy)
			# Skip center (player spawn) and fortress area
			if pos.distance_to(center) < 500:
				continue
			if pos.distance_to(fp) < 600:
				continue
			# 60% chance to place a base at this intersection
			if randf() < 0.6:
				base_positions.append(pos)

	for pos in base_positions:
		_create_base(pos)


func _create_base(center: Vector2):
	var size = randi_range(150, 250)
	var half = size / 2.0

	# Fence perimeter with gate
	_create_fence_line(center + Vector2(-half, -half), center + Vector2(half, -half), true)
	_create_fence_line(center + Vector2(-half, half), center + Vector2(half, half), true)
	_create_fence_line(center + Vector2(-half, -half), center + Vector2(-half, half), false)
	_create_fence_line(center + Vector2(half, -half), center + Vector2(half, half), false)

	# Internal obstacles (sandbags, barricades, crates)
	var obstacle_textures = [sandbag_tex, sandbag_beige, barricade_tex, crate_tex, crate_metal]
	for i in randi_range(4, 8):
		var tex = obstacle_textures[randi() % obstacle_textures.size()]
		var pos = center + Vector2(randf_range(-half + 30, half - 30), randf_range(-half + 30, half - 30))
		_place_obstacle(pos, tex, Vector2(32, 24))

	# Barrels
	for i in randi_range(2, 4):
		var tex = [barrel_tex, barrel_red, barrel_green][randi() % 3]
		var pos = center + Vector2(randf_range(-half + 20, half - 20), randf_range(-half + 20, half - 20))
		_place_obstacle(pos, tex, Vector2(20, 20))

	# Machine Gunners (2-4 per base)
	for i in randi_range(2, 4):
		var gunner = machine_gunner_scene.instantiate()
		gunner.global_position = center + Vector2(randf_range(-half + 30, half - 30), randf_range(-half + 30, half - 30))
		call_deferred("add_child", gunner)


# --- SAFE ZONES (farmhouses) ---
func _create_safe_zones():
	var arena = GameManager.ARENA_SIZE
	var fp = GameManager.FORTRESS_POS
	var center = arena / 2.0

	# Place 6-10 farmhouses across the map
	for i in randi_range(6, 10):
		var pos: Vector2
		for attempt in 20:
			pos = Vector2(randf_range(400, arena.x - 400), randf_range(400, arena.y - 400))
			# Don't place near center, fortress, or roads
			if pos.distance_to(center) < 400:
				continue
			if pos.distance_to(fp) < 600:
				continue
			var near_road = false
			for ry in h_roads:
				if abs(pos.y - ry) < 150:
					near_road = true
					break
			if not near_road:
				for rx in v_roads:
					if abs(pos.x - rx) < 150:
						near_road = true
						break
			if not near_road:
				break
		var zone = safe_zone_scene.instantiate()
		zone.global_position = pos
		call_deferred("add_child", zone)


# --- FORTRESS ---
func _create_fortress():
	var fp = GameManager.FORTRESS_POS
	var fs = GameManager.FORTRESS_SIZE
	var half = fs / 2.0

	# Fence walls around perimeter
	_create_fence_line(fp - half, fp + Vector2(half.x, -half.y), true)  # Top
	_create_fence_line(fp + Vector2(-half.x, half.y), fp + half, true)  # Bottom
	_create_fence_line(fp - half, fp + Vector2(-half.x, half.y), false)  # Left
	_create_fence_line(fp + Vector2(half.x, -half.y), fp + half, false)  # Right

	# Gate opening (remove middle fences on south side later - just leave a gap)
	# Internal obstacles
	var obstacle_textures = [barricade_tex, barricade_wood, sandbag_tex, sandbag_beige, crate_metal, crate_tex]
	for i in 20:
		var tex = obstacle_textures[randi() % obstacle_textures.size()]
		var pos = fp + Vector2(randf_range(-200, 200), randf_range(-200, 200))
		_place_obstacle(pos, tex, Vector2(36, 28))

	# Barrels inside
	for i in 8:
		var tex = [barrel_tex, barrel_red][randi() % 2]
		var pos = fp + Vector2(randf_range(-180, 180), randf_range(-180, 180))
		_place_obstacle(pos, tex, Vector2(22, 22))


func _create_fence_line(from: Vector2, to: Vector2, horizontal: bool):
	var dist = from.distance_to(to)
	var spacing = 40.0
	var count = int(dist / spacing)
	var dir = (to - from).normalized()
	# Leave a gap in the middle (gate)
	var mid = count / 2
	for i in count:
		if abs(i - mid) <= 1:
			continue  # Gate opening
		var pos = from + dir * (i * spacing + spacing / 2)
		var body = StaticBody2D.new()
		body.collision_layer = 8
		body.collision_mask = 0
		body.position = pos
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(36, 12) if horizontal else Vector2(12, 36)
		shape.shape = rect
		body.add_child(shape)
		var spr = Sprite2D.new()
		spr.texture = [fence_tex, fence_yellow][randi() % 2]
		if not horizontal:
			spr.rotation = PI / 2
		body.add_child(spr)
		add_child(body)

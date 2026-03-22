extends Area2D

enum PickupType {HEALTH, AMMO, SPEED_BOOST, DAMAGE_BOOST, MONEY, GOLD}

var pickup_type: int = 0  # Set before adding to tree

const COLORS = {
	0: Color(0.2, 0.9, 0.2),   # HEALTH - green
	1: Color(0.9, 0.9, 0.2),   # AMMO - yellow
	2: Color(0.2, 0.5, 1.0),   # SPEED_BOOST - blue
	3: Color(1.0, 0.2, 0.2),   # DAMAGE_BOOST - red
	4: Color(1.0, 0.85, 0.0),  # MONEY - gold
	5: Color(1.0, 0.7, 0.0),   # GOLD - bright gold
}

const NAMES = {
	0: "Health",
	1: "Ammo",
	2: "Speed Up",
	3: "Damage Up",
	4: "Money",
	5: "Gold",
}

var lifetime: float = 15.0


func _ready():
	$Body.color = COLORS.get(pickup_type, Color.WHITE)
	_spawn_drop_text()
	get_tree().create_timer(lifetime).timeout.connect(func(): call_deferred("queue_free"))


func _spawn_drop_text():
	# Floating text showing what dropped
	var text = NAMES.get(pickup_type, "???")
	var color = COLORS.get(pickup_type, Color.WHITE)
	_create_floating_text(global_position, text, color)


func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		_apply(body)
		call_deferred("queue_free")


func _apply(player):
	var pickup_text = ""
	var pickup_color = COLORS.get(pickup_type, Color.WHITE)

	match pickup_type:
		PickupType.HEALTH:
			player.hp = min(player.hp + 30, player.max_hp)
			GameManager.health_changed.emit(player.hp, player.max_hp)
			pickup_text = "+30 HP"
		PickupType.AMMO:
			player.add_ammo(30)
			pickup_text = "+30 Ammo"
		PickupType.SPEED_BOOST:
			player.speed += 80
			get_tree().create_timer(5.0).timeout.connect(
				func():
					if is_instance_valid(player):
						player.speed -= 80
			)
			pickup_text = "Speed Up! (5s)"
		PickupType.DAMAGE_BOOST:
			player.damage_bonus += 8
			get_tree().create_timer(5.0).timeout.connect(
				func():
					if is_instance_valid(player):
						player.damage_bonus -= 8
			)
			pickup_text = "Damage Up! (5s)"
		PickupType.MONEY:
			var amount = _random_money()
			GameManager.add_money(amount)
			pickup_text = "+$%d" % amount
		PickupType.GOLD:
			player.gold += 1
			pickup_text = "+1 Gold (sell at village)"

	_create_floating_text(global_position, pickup_text, pickup_color)


func _create_floating_text(pos: Vector2, text: String, color: Color):
	if not is_inside_tree() or not get_tree().current_scene:
		return
	var label = Label.new()
	label.text = text
	label.global_position = pos + Vector2(-30, -20)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.z_index = 100
	get_tree().current_scene.add_child(label)
	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40, 1.5)
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	tween.chain().tween_callback(func():
		if is_instance_valid(label):
			label.queue_free()
	)


func _random_money() -> int:
	var roll = randf()
	if roll < 0.5:
		return 100
	elif roll < 0.75:
		return 200
	elif roll < 0.9:
		return 300
	elif roll < 0.97:
		return 400
	else:
		return 500

extends Area2D

enum PickupType {HEALTH, AMMO, SPEED_BOOST, DAMAGE_BOOST, MONEY}

var pickup_type: int = 0  # Set before adding to tree

const COLORS = {
	0: Color(0.2, 0.9, 0.2),   # HEALTH - green
	1: Color(0.9, 0.9, 0.2),   # AMMO - yellow
	2: Color(0.2, 0.5, 1.0),   # SPEED_BOOST - blue
	3: Color(1.0, 0.2, 0.2),   # DAMAGE_BOOST - red
	4: Color(1.0, 0.85, 0.0),  # MONEY - gold
}

const NAMES = {
	0: "Health",
	1: "Ammo",
	2: "Speed Up",
	3: "Damage Up",
	4: "Money",
}

var lifetime: float = 15.0


func _ready():
	$Body.color = COLORS.get(pickup_type, Color.WHITE)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		_apply(body)
		queue_free()


func _apply(player):
	match pickup_type:
		PickupType.HEALTH:
			player.hp = min(player.hp + 30, player.max_hp)
			GameManager.health_changed.emit(player.hp, player.max_hp)
		PickupType.AMMO:
			player.add_ammo(30)
		PickupType.SPEED_BOOST:
			player.speed += 80
			get_tree().create_timer(5.0).timeout.connect(
				func():
					if is_instance_valid(player):
						player.speed -= 80
			)
		PickupType.DAMAGE_BOOST:
			player.damage_bonus += 8
			get_tree().create_timer(5.0).timeout.connect(
				func():
					if is_instance_valid(player):
						player.damage_bonus -= 8
			)
		PickupType.MONEY:
			var amount = _random_money()
			GameManager.add_money(amount)


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

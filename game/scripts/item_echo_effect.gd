extends Node2D

signal damage_dealt(amount: int, at_position: Vector2, color: Color)

var echo_id := ""
var echo_definition := {}
var effect := {}
var enemies: Array = []
var player: Node
var timer := 0.0
var tick_timer := 0.0
var duration := 1.2
var damage_per_second := 0
var radius := 118.0

func configure(id: String, source_player: Node, arena_enemies: Array, definition := {}) -> void:
	echo_id = id
	echo_definition = definition
	effect = echo_definition.get("effect", {})
	player = source_player
	enemies = arena_enemies
	match str(effect.get("type", "")):
		"damage_orb":
			duration = float(effect.get("durationSeconds", 4.0))
			damage_per_second = _scale_int(int(effect.get("damagePerSecond", 5)))
		"delayed_second_hit":
			duration = float(effect.get("delaySeconds", 0.25)) + 0.20
		"bell_pulse":
			duration = 0.75
		"brief_armor_gain", "restore_will", "chill_nearby", "vulnerable_nearby":
			duration = float(effect.get("durationSeconds", 1.25))
		_:
			duration = 1.25

func _process(delta: float) -> void:
	timer += delta
	tick_timer -= delta
	if str(effect.get("type", "")) == "damage_orb" and tick_timer <= 0.0:
		tick_timer = 1.0
		_damage_nearby(damage_per_second, Color(1.0, 0.42, 0.05))
	if timer >= duration:
		queue_free()
	queue_redraw()

func apply_instant() -> void:
	match str(effect.get("type", "")):
		"restore_will":
			if is_instance_valid(player):
				player.current_will = mini(player.max_will, player.current_will + _scale_int(int(effect.get("amount", 8))))
		"brief_armor_gain":
			if is_instance_valid(player):
				player.apply_status("bone_memory", float(effect.get("durationSeconds", 4.0)), float(_scale_int(int(effect.get("armor", 3)))))
		"chill_nearby":
			for target in _nearby_enemies():
				target.apply_status("chill", float(effect.get("durationSeconds", 3.0)), _scale_percent(float(effect.get("slowPercent", 30)) / 100.0))
		"vulnerable_nearby":
			for target in _nearby_enemies():
				target.apply_status("vulnerable", float(effect.get("durationSeconds", 4.0)), _scale_percent(float(effect.get("damageTakenPercent", 20)) / 100.0))
		"bell_pulse":
			_damage_nearby(_scale_int(int(effect.get("damage", 16))), Color(0.55, 0.85, 1.0))

func _damage_nearby(amount: int, color: Color) -> void:
	for target in _nearby_enemies():
		target.take_damage(amount)
		damage_dealt.emit(amount, target.global_position + Vector2(0, -54), color)

func _echo_power_multiplier() -> float:
	if is_instance_valid(player) and player.has_method("echo_power_multiplier"):
		return player.echo_power_multiplier()
	return 1.0

func _scale_int(value: int) -> int:
	return maxi(1, int(roundi(float(value) * _echo_power_multiplier())))

func _scale_percent(value: float) -> float:
	return clampf(value * _echo_power_multiplier(), 0.0, 0.95)

func _nearby_enemies() -> Array:
	var nearby: Array = []
	for target in enemies:
		if is_instance_valid(target) and target.alive and global_position.distance_to(target.global_position) <= radius:
			nearby.append(target)
	return nearby

func _draw() -> void:
	var color := Color(0.80, 0.80, 1.0, 0.18)
	match echo_id:
		"echo_spectral_ember":
			color = Color(1.0, 0.35, 0.05, 0.22)
		"echo_frost_grave":
			color = Color(0.45, 0.85, 1.0, 0.22)
		"echo_decay_bloom":
			color = Color(0.25, 0.85, 0.25, 0.22)
		"echo_bone_memory":
			color = Color(0.78, 0.72, 0.58, 0.24)
		"echo_burial_toll":
			color = Color(0.55, 0.85, 1.0, 0.25)
		"echo_last_duel":
			color = Color(0.70, 0.85, 1.0, 0.24)
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(color.r, color.g, color.b, 0.55), 3.0)
	if echo_id == "echo_last_duel":
		draw_line(Vector2(-34, 18), Vector2(38, -18), Color(0.82, 0.92, 1.0, 0.80), 5.0)

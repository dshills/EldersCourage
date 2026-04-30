extends Node2D

signal damage_dealt(amount: int, at_position: Vector2, color: Color)

const RADIUS := 118.0

var echo_id := ""
var enemies: Array = []
var player: Node
var timer := 0.0
var tick_timer := 0.0
var duration := 1.2
var damage_per_second := 0

func configure(id: String, source_player: Node, arena_enemies: Array) -> void:
	echo_id = id
	player = source_player
	enemies = arena_enemies
	match echo_id:
		"echo_spectral_ember":
			duration = 4.0
			damage_per_second = 5
		"echo_burial_toll":
			duration = 0.75
		_:
			duration = 1.25

func _process(delta: float) -> void:
	timer += delta
	tick_timer -= delta
	if echo_id == "echo_spectral_ember" and tick_timer <= 0.0:
		tick_timer = 1.0
		_damage_nearby(damage_per_second, Color(1.0, 0.42, 0.05))
	if timer >= duration:
		queue_free()
	queue_redraw()

func apply_instant() -> void:
	match echo_id:
		"echo_blood_refund":
			if is_instance_valid(player):
				player.current_will = mini(player.max_will, player.current_will + 8)
		"echo_frost_grave":
			for target in _nearby_enemies():
				target.apply_status("chill", 3.0, 0.30)
		"echo_decay_bloom":
			for target in _nearby_enemies():
				target.apply_status("vulnerable", 4.0, 0.20)
		"echo_burial_toll":
			_damage_nearby(16, Color(0.55, 0.85, 1.0))

func _damage_nearby(amount: int, color: Color) -> void:
	for target in _nearby_enemies():
		target.take_damage(amount)
		damage_dealt.emit(amount, target.global_position + Vector2(0, -54), color)

func _nearby_enemies() -> Array:
	var nearby: Array = []
	for target in enemies:
		if is_instance_valid(target) and target.alive and global_position.distance_to(target.global_position) <= RADIUS:
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
		"echo_burial_toll":
			color = Color(0.55, 0.85, 1.0, 0.25)
	draw_circle(Vector2.ZERO, RADIUS, color)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, Color(color.r, color.g, color.b, 0.55), 3.0)

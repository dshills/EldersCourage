extends CharacterBody2D

signal damage_dealt(amount: int, at_position: Vector2, color: Color)
signal died
signal summon_requested(position: Vector2)

const MOVE_SPEED := 72.0
const BELL_SLAM_DAMAGE := 28
const ECHO_TOLL_DAMAGE := 18
const MELEE_RANGE := 100.0

var max_health := 260
var current_health := 260
var target: Node2D
var alive := true
var attack_timer := 1.0
var attack_index := 0
var telegraph_timer := 0.0
var pending_attack := ""
var pending_position := Vector2.ZERO
var statuses := {}
var dot_timer := 0.0

func _physics_process(delta: float) -> void:
	if not alive:
		velocity = Vector2.ZERO
		return
	_process_statuses(delta)
	if telegraph_timer > 0.0:
		telegraph_timer -= delta
		velocity = Vector2.ZERO
		if telegraph_timer <= 0.0:
			_finish_pending_attack()
		queue_redraw()
		return
	if not is_instance_valid(target) or not target.alive:
		velocity = Vector2.ZERO
		return
	attack_timer -= delta
	var offset := target.global_position - global_position
	if offset.length() > MELEE_RANGE:
		velocity = offset.normalized() * MOVE_SPEED * _speed_multiplier()
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	if attack_timer <= 0.0:
		_choose_attack()
	queue_redraw()

func _choose_attack() -> void:
	attack_timer = 2.2
	attack_index = (attack_index + 1) % 3
	match attack_index:
		0:
			_start_telegraph("bell_slam", 0.8)
		1:
			summon_requested.emit(global_position + Vector2(randf_range(-90, 90), randf_range(-70, 70)))
		_:
			_start_telegraph("echo_toll", 1.0)

func _start_telegraph(attack_name: String, duration: float) -> void:
	pending_attack = attack_name
	pending_position = target.global_position if is_instance_valid(target) else global_position
	telegraph_timer = duration

func _finish_pending_attack() -> void:
	if not is_instance_valid(target) or not target.alive:
		return
	match pending_attack:
		"bell_slam":
			if global_position.distance_to(target.global_position) <= 125.0:
				target.take_damage(BELL_SLAM_DAMAGE)
				damage_dealt.emit(BELL_SLAM_DAMAGE, target.global_position + Vector2(0, -56), Color(0.85, 0.85, 1.0))
		"echo_toll":
			if pending_position.distance_to(target.global_position) <= 90.0:
				target.take_damage(ECHO_TOLL_DAMAGE)
				target.apply_status("vulnerable", 3.0, 0.15)
				damage_dealt.emit(ECHO_TOLL_DAMAGE, target.global_position + Vector2(0, -56), Color(0.55, 0.85, 1.0))
	pending_attack = ""

func take_damage(amount: int) -> void:
	if not alive:
		return
	if statuses.has("vulnerable"):
		amount = int(roundi(float(amount) * (1.0 + statuses["vulnerable"]["value"])))
	current_health = maxi(0, current_health - amount)
	if current_health <= 0:
		alive = false
		died.emit()
		queue_free()

func apply_status(status_name: String, duration: float, value: float) -> void:
	statuses[status_name] = { "duration": duration, "value": value }

func apply_haunted_modifier(_damage_multiplier: float, _speed_multiplier: float) -> void:
	pass

func _process_statuses(delta: float) -> void:
	var expired: Array[String] = []
	for status_name in statuses.keys():
		statuses[status_name]["duration"] -= delta
		if statuses[status_name]["duration"] <= 0.0:
			expired.append(status_name)
	for status_name in expired:
		statuses.erase(status_name)
	dot_timer -= delta
	if dot_timer <= 0.0:
		dot_timer = 1.0
		if statuses.has("bleed"):
			take_damage(int(statuses["bleed"]["value"]))
			damage_dealt.emit(int(statuses["bleed"]["value"]), global_position + Vector2(0, -62), Color(0.90, 0.05, 0.05))
		if statuses.has("burn"):
			take_damage(int(statuses["burn"]["value"]))
			damage_dealt.emit(int(statuses["burn"]["value"]), global_position + Vector2(0, -62), Color(1.0, 0.45, 0.05))

func _speed_multiplier() -> float:
	if statuses.has("chill"):
		return 1.0 - statuses["chill"]["value"]
	return 1.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, 42, Color(0.18, 0.16, 0.14))
	draw_circle(Vector2(0, -8), 24, Color(0.62, 0.55, 0.42))
	draw_line(Vector2(-34, 32), Vector2(34, 32), Color(0.95, 0.80, 0.28), 6.0)
	if telegraph_timer > 0.0:
		if pending_attack == "bell_slam":
			draw_arc(Vector2.ZERO, 125.0, 0.0, TAU, 48, Color(1.0, 0.85, 0.20), 5.0)
		elif pending_attack == "echo_toll":
			draw_circle(to_local(pending_position), 90.0, Color(0.45, 0.75, 1.0, 0.18))
	var health_ratio := float(current_health) / float(max_health)
	draw_rect(Rect2(Vector2(-60, -66), Vector2(120, 8)), Color(0.12, 0.02, 0.02))
	draw_rect(Rect2(Vector2(-60, -66), Vector2(120 * health_ratio, 8)), Color(0.75, 0.12, 0.12))

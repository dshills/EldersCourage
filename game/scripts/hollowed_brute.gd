extends CharacterBody2D

signal damage_dealt(amount: int, at_position: Vector2, color: Color)
signal died

const MOVE_SPEED := 80.0
const SLAM_RANGE := 88.0
const SLAM_DAMAGE := 22
const SLAM_COOLDOWN := 2.4
const TELEGRAPH_TIME := 0.7

var damage_multiplier := 1.0
var speed_multiplier := 1.0
var max_health := 115
var current_health := 115
var target: Node2D
var slam_timer := 0.0
var telegraph_timer := 0.0
var alive := true
var statuses := {}
var dot_timer := 0.0

func _physics_process(delta: float) -> void:
	if not alive:
		velocity = Vector2.ZERO
		return
	_process_statuses(delta)
	slam_timer = maxf(0.0, slam_timer - delta)
	if telegraph_timer > 0.0:
		telegraph_timer -= delta
		velocity = Vector2.ZERO
		if telegraph_timer <= 0.0:
			_finish_slam()
		queue_redraw()
		return
	if not is_instance_valid(target) or not target.alive:
		velocity = Vector2.ZERO
		return
	var offset := target.global_position - global_position
	if offset.length() > SLAM_RANGE:
		velocity = offset.normalized() * MOVE_SPEED * speed_multiplier * _speed_multiplier()
	else:
		velocity = Vector2.ZERO
		if slam_timer <= 0.0:
			slam_timer = SLAM_COOLDOWN
			telegraph_timer = TELEGRAPH_TIME
	move_and_slide()
	queue_redraw()

func _finish_slam() -> void:
	if not is_instance_valid(target) or not target.alive:
		return
	var offset := target.global_position - global_position
	if offset.length() <= SLAM_RANGE + 16.0:
		var damage := int(roundi(float(SLAM_DAMAGE) * damage_multiplier))
		target.take_damage(damage)
		target.global_position += offset.normalized() * 55.0
		damage_dealt.emit(damage, target.global_position + Vector2(0, -54), Color(0.95, 0.30, 0.08))

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
	statuses[status_name] = {
		"duration": duration,
		"value": value,
	}

func apply_haunted_modifier(new_damage_multiplier: float, new_speed_multiplier: float) -> void:
	damage_multiplier = maxf(damage_multiplier, new_damage_multiplier)
	speed_multiplier = maxf(speed_multiplier, new_speed_multiplier)

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
			damage_dealt.emit(int(statuses["bleed"]["value"]), global_position + Vector2(0, -56), Color(0.90, 0.05, 0.05))
		if statuses.has("burn"):
			take_damage(int(statuses["burn"]["value"]))
			damage_dealt.emit(int(statuses["burn"]["value"]), global_position + Vector2(0, -56), Color(1.0, 0.45, 0.05))

func _speed_multiplier() -> float:
	if statuses.has("chill"):
		return 1.0 - statuses["chill"]["value"]
	return 1.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, 30, Color(0.32, 0.29, 0.25))
	draw_rect(Rect2(Vector2(-22, -10), Vector2(44, 22)), Color(0.46, 0.42, 0.35))
	if telegraph_timer > 0.0:
		draw_arc(Vector2.ZERO, SLAM_RANGE, 0.0, TAU, 40, Color(1.0, 0.2, 0.05), 4.0)
	var health_ratio := float(current_health) / float(max_health)
	draw_rect(Rect2(Vector2(-30, -46), Vector2(60, 6)), Color(0.12, 0.02, 0.02))
	draw_rect(Rect2(Vector2(-30, -46), Vector2(60 * health_ratio, 6)), Color(0.75, 0.12, 0.12))
	if statuses.has("vulnerable"):
		draw_arc(Vector2.ZERO, 39, 0.0, TAU, 24, Color(0.45, 0.85, 1.0), 2.0)

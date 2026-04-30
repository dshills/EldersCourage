extends CharacterBody2D

signal damage_dealt(amount: int, at_position: Vector2, color: Color)
signal died

const MOVE_SPEED := 130.0
const ATTACK_RANGE := 48.0
const ATTACK_DAMAGE := 10
const ATTACK_COOLDOWN := 0.9

var damage_multiplier := 1.0
var speed_multiplier := 1.0
var max_health := 60
var current_health := 60
var target: Node2D
var attack_timer := 0.0
var alive := true
var statuses := {}
var dot_timer := 0.0

func _physics_process(delta: float) -> void:
	if not alive:
		velocity = Vector2.ZERO
		return
	_process_statuses(delta)
	attack_timer = maxf(0.0, attack_timer - delta)
	if not is_instance_valid(target) or not target.alive:
		velocity = Vector2.ZERO
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	if distance > ATTACK_RANGE:
		velocity = offset.normalized() * MOVE_SPEED * speed_multiplier * _speed_multiplier()
	else:
		velocity = Vector2.ZERO
		if attack_timer <= 0.0:
			attack_timer = ATTACK_COOLDOWN
			var damage := int(roundi(float(ATTACK_DAMAGE) * damage_multiplier))
			target.take_damage(damage)
			damage_dealt.emit(damage, target.global_position + Vector2(0, -54), Color(0.9, 0.2, 0.2))
	move_and_slide()
	queue_redraw()

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
			damage_dealt.emit(int(statuses["bleed"]["value"]), global_position + Vector2(0, -50), Color(0.90, 0.05, 0.05))
		if statuses.has("burn"):
			take_damage(int(statuses["burn"]["value"]))
			damage_dealt.emit(int(statuses["burn"]["value"]), global_position + Vector2(0, -50), Color(1.0, 0.45, 0.05))

func _speed_multiplier() -> float:
	if statuses.has("chill"):
		return 1.0 - statuses["chill"]["value"]
	return 1.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, 20, Color(0.55, 0.50, 0.43))
	draw_circle(Vector2(-7, -5), 3, Color(0.05, 0.02, 0.02))
	draw_circle(Vector2(7, -5), 3, Color(0.05, 0.02, 0.02))
	var health_ratio := float(current_health) / float(max_health)
	draw_rect(Rect2(Vector2(-24, -34), Vector2(48, 5)), Color(0.12, 0.02, 0.02))
	draw_rect(Rect2(Vector2(-24, -34), Vector2(48 * health_ratio, 5)), Color(0.75, 0.12, 0.12))
	if statuses.has("bleed"):
		draw_arc(Vector2.ZERO, 27, 0.0, TAU, 24, Color(0.85, 0.02, 0.02), 2.0)
	if statuses.has("vulnerable"):
		draw_arc(Vector2.ZERO, 31, 0.0, TAU, 24, Color(0.45, 0.85, 1.0), 2.0)

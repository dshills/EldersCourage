extends CharacterBody2D

signal damage_dealt(amount: int, at_position: Vector2, color: Color)
signal died

const ProjectileScene := preload("res://scripts/witch_projectile.gd")
const WitchTexture := preload("res://assets/sprites/enemies/ash_witch.png")
const MOVE_SPEED := 105.0
const KEEP_DISTANCE := 210.0
const SHOOT_RANGE := 390.0
const SHOOT_COOLDOWN := 1.75

var damage_multiplier := 1.0
var speed_multiplier := 1.0
var elite_damage_multiplier := 1.0
var elite_speed_multiplier := 1.0
var haunted_damage_multiplier := 1.0
var haunted_speed_multiplier := 1.0
var max_health := 42
var current_health := 42
var attack_damage := 12
var target: Node2D
var shoot_timer := 0.7
var alive := true
var statuses := {}
var dot_timer := 0.0

func _physics_process(delta: float) -> void:
	if not alive:
		velocity = Vector2.ZERO
		return
	_process_statuses(delta)
	shoot_timer = maxf(0.0, shoot_timer - delta)
	if not is_instance_valid(target) or not target.alive:
		velocity = Vector2.ZERO
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	velocity = Vector2.ZERO
	if distance < KEEP_DISTANCE:
		velocity = -offset.normalized() * MOVE_SPEED * speed_multiplier * _speed_multiplier()
	elif distance > SHOOT_RANGE:
		velocity = offset.normalized() * MOVE_SPEED * speed_multiplier * _speed_multiplier()
	elif shoot_timer <= 0.0:
		shoot_timer = SHOOT_COOLDOWN
		_shoot(offset.normalized())
	move_and_slide()
	queue_redraw()

func _shoot(direction: Vector2) -> void:
	var projectile := ProjectileScene.new()
	projectile.global_position = global_position
	projectile.direction = direction
	projectile.target = target
	projectile.damage = attack_damage
	projectile.damage_multiplier = damage_multiplier
	projectile.damage_dealt.connect(func(amount: int, at_position: Vector2, color: Color) -> void:
		damage_dealt.emit(amount, at_position, color)
	)
	get_parent().add_child(projectile)

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
	haunted_damage_multiplier = new_damage_multiplier
	haunted_speed_multiplier = new_speed_multiplier
	_refresh_multipliers()

func clear_haunted_modifier() -> void:
	haunted_damage_multiplier = 1.0
	haunted_speed_multiplier = 1.0
	_refresh_multipliers()

func apply_elite_modifier(new_damage_multiplier: float, new_speed_multiplier: float) -> void:
	elite_damage_multiplier = new_damage_multiplier
	elite_speed_multiplier = new_speed_multiplier
	_refresh_multipliers()

func _refresh_multipliers() -> void:
	damage_multiplier = elite_damage_multiplier * haunted_damage_multiplier
	speed_multiplier = elite_speed_multiplier * haunted_speed_multiplier

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
			damage_dealt.emit(int(statuses["bleed"]["value"]), global_position + Vector2(0, -48), Color(0.90, 0.05, 0.05))
		if statuses.has("burn"):
			take_damage(int(statuses["burn"]["value"]))
			damage_dealt.emit(int(statuses["burn"]["value"]), global_position + Vector2(0, -48), Color(1.0, 0.45, 0.05))

func _speed_multiplier() -> float:
	if statuses.has("chill"):
		return 1.0 - statuses["chill"]["value"]
	return 1.0

func _draw() -> void:
	draw_texture_rect(WitchTexture, Rect2(Vector2(-32, -32), Vector2(64, 64)), false)
	var health_ratio := float(current_health) / float(max_health)
	draw_rect(Rect2(Vector2(-24, -32), Vector2(48, 5)), Color(0.12, 0.02, 0.02))
	draw_rect(Rect2(Vector2(-24, -32), Vector2(48 * health_ratio, 5)), Color(0.75, 0.12, 0.12))
	if statuses.has("vulnerable"):
		draw_arc(Vector2.ZERO, 29, 0.0, TAU, 24, Color(0.45, 0.85, 1.0), 2.0)

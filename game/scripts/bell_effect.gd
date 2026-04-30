extends Node2D

signal damage_dealt(amount: int, at_position: Vector2, color: Color)

const RADIUS := 150.0
const DELAY := 0.65
const DAMAGE := 34

var enemies: Array = []
var timer := 0.0
var fired := false

func _process(delta: float) -> void:
	timer += delta
	if not fired and timer >= DELAY:
		fired = true
		_release_bell()
	if timer >= 1.25:
		queue_free()
	queue_redraw()

func _release_bell() -> void:
	for target in enemies:
		if not is_instance_valid(target) or not target.alive:
			continue
		if global_position.distance_to(target.global_position) <= RADIUS:
			target.take_damage(DAMAGE)
			target.apply_status("vulnerable", 4.0, 0.20)
			target.apply_status("chill", 2.5, 0.30)
			damage_dealt.emit(DAMAGE, target.global_position + Vector2(0, -58), Color(0.55, 0.85, 1.0))

func _draw() -> void:
	var progress := clampf(timer / DELAY, 0.0, 1.0)
	var color := Color(0.30, 0.65, 1.0, 0.25 if not fired else 0.55)
	draw_arc(Vector2.ZERO, RADIUS * progress, 0.0, TAU, 48, color, 5.0)
	if fired:
		draw_circle(Vector2.ZERO, RADIUS, Color(0.30, 0.65, 1.0, 0.08))

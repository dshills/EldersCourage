extends Node2D

signal damage_dealt(amount: int, at_position: Vector2, color: Color)

const SPEED := 230.0
const DAMAGE := 12

var direction := Vector2.RIGHT
var target: Node2D
var lifetime := 2.7
var damage_multiplier := 1.0

func _process(delta: float) -> void:
	global_position += direction.normalized() * SPEED * delta
	lifetime -= delta
	if is_instance_valid(target) and target.alive and global_position.distance_to(target.global_position) <= 24.0:
		var damage := int(roundi(float(DAMAGE) * damage_multiplier))
		target.take_damage(damage)
		target.apply_status("burn", 3.0, 3.0)
		damage_dealt.emit(damage, target.global_position + Vector2(0, -50), Color(1.0, 0.35, 0.05))
		queue_free()
		return
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 8, Color(1.0, 0.36, 0.04))
	draw_arc(Vector2.ZERO, 13, 0.0, TAU, 16, Color(1.0, 0.72, 0.20), 2.0)

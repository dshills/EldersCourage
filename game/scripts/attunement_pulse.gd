extends Node2D

var lifetime := 0.8

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var progress := 1.0 - clampf(lifetime / 0.8, 0.0, 1.0)
	var radius := lerpf(18.0, 76.0, progress)
	var alpha := 1.0 - progress
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.75, 0.55, 1.0, alpha), 5.0)
	draw_arc(Vector2.ZERO, radius * 0.62, 0.0, TAU, 36, Color(1.0, 0.80, 0.35, alpha * 0.8), 3.0)

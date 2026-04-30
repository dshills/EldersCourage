extends Node2D

var lifetime := 0.22
var spark_color := Color(1.0, 0.85, 0.35)

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var alpha := clampf(lifetime / 0.22, 0.0, 1.0)
	var color := Color(spark_color.r, spark_color.g, spark_color.b, alpha)
	draw_line(Vector2(-12, 0), Vector2(12, 0), color, 3.0)
	draw_line(Vector2(0, -12), Vector2(0, 12), color, 3.0)
	draw_arc(Vector2.ZERO, 14.0 * alpha, 0.0, TAU, 18, color, 2.0)

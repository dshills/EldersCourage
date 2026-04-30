extends Area2D

signal entered

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 36
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body.has_method("add_item"):
		entered.emit()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 34, Color(0.25, 0.55, 1.0, 0.25))
	draw_arc(Vector2.ZERO, 42, 0.0, TAU, 36, Color(0.55, 0.85, 1.0), 5.0)
	draw_arc(Vector2.ZERO, 24, 0.0, TAU, 36, Color(0.95, 0.95, 1.0), 3.0)

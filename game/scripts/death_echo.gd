extends Area2D

signal reclaimed

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 30
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body.has_method("award_attunement_xp"):
		reclaimed.emit()
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 26, Color(0.45, 0.15, 0.85, 0.32))
	draw_arc(Vector2.ZERO, 34, 0.0, TAU, 36, Color(0.75, 0.45, 1.0), 4.0)
	draw_line(Vector2(-14, 0), Vector2(14, 0), Color(0.85, 0.78, 1.0), 3.0)

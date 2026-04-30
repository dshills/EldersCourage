extends Area2D

signal opened(at_position: Vector2)

var opened_once := false

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(44, 34)
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if opened_once or not body.has_method("add_item"):
		return
	opened_once = true
	opened.emit(global_position)
	queue_free()

func _draw() -> void:
	draw_rect(Rect2(Vector2(-22, -17), Vector2(44, 34)), Color(0.42, 0.24, 0.08))
	draw_rect(Rect2(Vector2(-18, -13), Vector2(36, 26)), Color(0.70, 0.45, 0.16), false, 3.0)
	draw_circle(Vector2(0, 0), 4, Color(1.0, 0.82, 0.22))

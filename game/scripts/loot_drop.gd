extends Area2D

signal picked_up(item: Dictionary)

var item := {}

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body.has_method("add_item"):
		body.add_item(item)
		picked_up.emit(item)
		queue_free()

func _draw() -> void:
	var color := _rarity_color(str(item.get("rarity", "worn")))
	draw_circle(Vector2.ZERO, 14, color)
	draw_arc(Vector2.ZERO, 18, 0.0, TAU, 20, Color(1, 1, 1, 0.55), 2.0)

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"forged":
			return Color(0.35, 0.75, 0.95)
		"relic":
			return Color(0.70, 0.45, 1.0)
		"accursed":
			return Color(0.95, 0.20, 0.35)
		_:
			return Color(0.75, 0.72, 0.62)

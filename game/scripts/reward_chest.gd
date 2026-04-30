extends Area2D

signal opened(at_position: Vector2)

const ChestTexture := preload("res://assets/sprites/loot/reward_chest.png")

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
	draw_circle(Vector2(0, 0), 32, Color(0.95, 0.74, 0.24, 0.18))
	draw_texture_rect(ChestTexture, Rect2(Vector2(-48, -32), Vector2(96, 64)), false)
	draw_arc(Vector2.ZERO, 32, 0.0, TAU, 32, Color(1.0, 0.82, 0.22, 0.65), 2.0)

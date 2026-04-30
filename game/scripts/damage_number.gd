extends Label

var lifetime := 0.75
var velocity := Vector2(0, -48)

func _ready() -> void:
	add_theme_font_size_override("font_size", 22)

func _process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	modulate.a = clampf(lifetime / 0.75, 0.0, 1.0)
	if lifetime <= 0.0:
		queue_free()

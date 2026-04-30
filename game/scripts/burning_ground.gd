extends Area2D

signal damage_dealt(amount: int, at_position: Vector2, color: Color)

var lifetime := 3.0
var tick_timer := 0.0
var player: Node
var damage := 4
var radius := 34.0

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	add_child(collision)

func _process(delta: float) -> void:
	lifetime -= delta
	tick_timer -= delta
	if tick_timer <= 0.0:
		tick_timer = 0.75
		if is_instance_valid(player) and player.alive and global_position.distance_to(player.global_position) <= radius:
			player.take_damage(damage)
			damage_dealt.emit(damage, player.global_position + Vector2(0, -48), Color(1.0, 0.35, 0.05))
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.25, 0.02, 0.20))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(1.0, 0.45, 0.05), 3.0)

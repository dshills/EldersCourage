extends Area2D

signal damage_dealt(amount: int, at_position: Vector2, color: Color)

const DAMAGE := 4
const RADIUS := 34.0

var lifetime := 3.0
var tick_timer := 0.0
var player: Node

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	collision.shape = shape
	add_child(collision)

func _process(delta: float) -> void:
	lifetime -= delta
	tick_timer -= delta
	if tick_timer <= 0.0:
		tick_timer = 0.75
		if is_instance_valid(player) and player.alive and global_position.distance_to(player.global_position) <= RADIUS:
			player.take_damage(DAMAGE)
			damage_dealt.emit(DAMAGE, player.global_position + Vector2(0, -48), Color(1.0, 0.35, 0.05))
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.25, 0.02, 0.20))
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 24, Color(1.0, 0.45, 0.05), 3.0)

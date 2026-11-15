@tool
class_name CharSprite
extends Node2D
## PROVISIONAL ART. A tiny person drawn in code, origin at the feet.
## To be replaced by authored sprite sheets; keep set_motion() as the interface.

@export var coat := Color(0.35, 0.4, 0.45):
	set(v):
		coat = v
		queue_redraw()
@export var accent := Color(0.7, 0.45, 0.2):
	set(v):
		accent = v
		queue_redraw()
@export var skin := Color(0.78, 0.6, 0.48):
	set(v):
		skin = v
		queue_redraw()
@export var hood := false:
	set(v):
		hood = v
		queue_redraw()

var _dir := 0  # 0 down, 1 up, 2 left, 3 right
var _moving := false
var _t := 0.0
var _frame := 0


func set_motion(facing: Vector2, moving: bool) -> void:
	var d := _dir
	if facing != Vector2.ZERO:
		if absf(facing.x) > absf(facing.y):
			d = 2 if facing.x < 0.0 else 3
		else:
			d = 1 if facing.y < 0.0 else 0
	if d != _dir or moving != _moving:
		_dir = d
		_moving = moving
		if not moving:
			_frame = 0
			_t = 0.0
		queue_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not _moving:
		return
	_t += delta
	var f := int(_t * 8.0) % 4
	if f != _frame:
		_frame = f
		queue_redraw()


func _draw() -> void:
	var bob := -1.0 if (_moving and _frame % 2 == 1) else 0.0
	var boots := Color(0.1, 0.1, 0.12)
	var dark := coat.darkened(0.22)
	var side := _dir >= 2
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# legs
	var lift_a := 1.0 if (_moving and _frame == 1) else 0.0
	var lift_b := 1.0 if (_moving and _frame == 3) else 0.0
	if side:
		draw_rect(Rect2(-2 - lift_a * 2.0, -5, 2, 5 - lift_a), boots)
		draw_rect(Rect2(0 + lift_b * 2.0, -5, 2, 5 - lift_b), boots)
	else:
		draw_rect(Rect2(-3, -5, 2, 5 - lift_a), boots)
		draw_rect(Rect2(1, -5, 2, 5 - lift_b), boots)
	# coat
	var bw := 6.0 if side else 8.0
	draw_rect(Rect2(-bw * 0.5, -15 + bob, bw, 11), coat)
	draw_rect(Rect2(-bw * 0.5, -5 + bob, bw, 1), dark)
	draw_rect(Rect2(-bw * 0.5, -11 + bob, bw, 1), accent)
	if side:
		var swing := 0.0
		if _moving:
			swing = 1.0 if _frame < 2 else -1.0
		draw_rect(Rect2(-1 + swing, -14 + bob, 2, 6), dark)
	else:
		draw_rect(Rect2(-5, -14 + bob, 1, 6), dark)
		draw_rect(Rect2(4, -14 + bob, 1, 6), dark)
	# head
	var top := coat if hood else Color(0.14, 0.11, 0.1)
	draw_rect(Rect2(-3, -21 + bob, 6, 6), skin)
	draw_rect(Rect2(-4, -22 + bob, 8, 3), top)
	var eye := Color(0.08, 0.07, 0.08)
	match _dir:
		0:
			if hood:
				draw_rect(Rect2(-4, -20 + bob, 1, 5), top)
				draw_rect(Rect2(3, -20 + bob, 1, 5), top)
			draw_rect(Rect2(-2, -18 + bob, 1, 1), eye)
			draw_rect(Rect2(1, -18 + bob, 1, 1), eye)
		1:
			draw_rect(Rect2(-4, -22 + bob, 8, 7), top)
		2:
			draw_rect(Rect2(0, -22 + bob, 4, 7), top)
			draw_rect(Rect2(-3, -18 + bob, 1, 1), eye)
		3:
			draw_rect(Rect2(-4, -22 + bob, 4, 7), top)
			draw_rect(Rect2(2, -18 + bob, 1, 1), eye)

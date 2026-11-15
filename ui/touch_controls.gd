class_name TouchControls
extends Control
## Touch (and mouse) movement without on-screen buttons: drag anywhere to steer,
## tap to interact. Sits underneath every other control, so HUD chips and panels
## take their own touches first.

signal tapped

@export var deadzone := 5.0
@export var stick_radius := 22.0
@export var tap_ms := 350

var vector := Vector2.ZERO
## Run toggle for touch play (the HUD's RUN chip sets it); Shift does the same on keys.
var sprint := false

var _down := false
var _dragged := false
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO
var _t0 := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	Dialogue.started.connect(func(_id: String) -> void: release())


func release() -> void:
	_down = false
	_dragged = false
	vector = Vector2.ZERO
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_VISIBILITY_CHANGED:
		release()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_down = true
			_dragged = false
			_origin = mb.position
			_knob = mb.position
			_t0 = Time.get_ticks_msec()
		else:
			var was_tap := _down and not _dragged and Time.get_ticks_msec() - _t0 <= tap_ms
			release()
			if was_tap:
				tapped.emit()
		return
	var mm := event as InputEventMouseMotion
	if mm != null and _down:
		var d := mm.position - _origin
		if d.length() > deadzone:
			_dragged = true
		if _dragged:
			# floating stick: the origin trails the finger once it leaves the ring
			if d.length() > stick_radius:
				_origin = mm.position - d.normalized() * stick_radius
				d = mm.position - _origin
			vector = d / stick_radius
			_knob = mm.position
			queue_redraw()


func _draw() -> void:
	if not _dragged:
		return
	draw_arc(_origin, stick_radius, 0.0, TAU, 40, Color(1, 1, 1, 0.14), 1.0)
	draw_circle(_knob, 4.0, Color(1, 1, 1, 0.22))

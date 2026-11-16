class_name GridPlayer
extends GridActor
## The player on a TileWorld. Same outward interface as the other players (target,
## facing, try_interact, setup, camera, sprinting, touch) so main, the HUD and saves
## drive it alike. FireRed controls: tap a direction to turn, hold to walk, hold run
## (Shift / pad B / RUN) to run; walking into a wall plays a bump; steps chain with no
## pause while a direction is held. Doors trigger on arrival.

signal target_changed(target: Interactable)

## A tap shorter than this only turns the player.
const TURN_TIME := 0.09

var touch: TouchControls
var target: Interactable
var sprinting := false
var camera: Camera2D
var _held := Vector2i.ZERO
var _held_t := 0.0
var _arrived_warp := false


func setup(touch_controls: TouchControls, m: TileWorld) -> void:
	touch = touch_controls
	world = m
	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(m.bounds.size.x)
	camera.limit_bottom = int(m.bounds.size.y)
	camera.offset = Vector2(0, -8)
	add_child(camera)
	camera.make_current()
	tile = m.tile_of(position)
	position = m.foot(tile)
	m.claim(tile, self)


func _input_dir() -> Vector2i:
	if Dialogue.active:
		return Vector2i.ZERO
	var v := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if v.length() < 0.3 and touch != null:
		v = touch.vector
	if v.length() < 0.3:
		return Vector2i.ZERO
	if absf(v.x) > absf(v.y):
		return Vector2i(signi(int(signf(v.x))), 0)
	return Vector2i(0, signi(int(signf(v.y))))


func _physics_process(delta: float) -> void:
	if world == null:
		return
	# a position set from outside (load, spawn) snaps to its tile
	if not _moving and position != world.foot(tile):
		world.release(tile, self)
		tile = world.tile_of(position)
		position = world.foot(tile)
		world.claim(tile, self)
	var d := _input_dir()
	sprinting = d != Vector2i.ZERO and (Input.is_action_pressed(&"sprint") or (touch != null and touch.sprint))
	if d != _held:
		_held = d
		_held_t = 0.0
	else:
		_held_t += delta
	if not _moving and d != Vector2i.ZERO:
		var facing_i := Vector2i(roundi(facing.x), roundi(facing.y))
		if d != facing_i and _held_t < TURN_TIME:
			face(d)
		elif not try_step(d, sprinting):
			if _bump <= 0.0:
				_bump = 0.25
			_pose()
	_update_target()


func _on_arrived() -> void:
	var w := world.warp_at(tile)
	if not w.is_empty():
		GameState.travel_requested.emit(str(w["map"]), str(w["spawn"]))
		return
	# keep walking with no pause while the direction is still held
	var d := _input_dir()
	if d != Vector2i.ZERO and d == Vector2i(roundi(facing.x), roundi(facing.y)):
		try_step(d, sprinting)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and try_interact():
		get_viewport().set_input_as_handled()


func try_interact() -> bool:
	if Dialogue.active or _moving or target == null or not target.is_available():
		return false
	target.interact(self)
	return true


func face_now() -> void:
	_pose()


func _update_target() -> void:
	var best: Interactable = null
	if not _moving:
		best = world.interactable_at(tile + Vector2i(roundi(facing.x), roundi(facing.y)))
	if best != target:
		target = best
		target_changed.emit(target)

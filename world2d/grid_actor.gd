class_name GridActor
extends Node2D
## Someone who moves tile by tile on a TileWorld, FireRed style: a step glides from
## one tile to the next over `walk_time` (or `run_time`), the sheet's walk or run frames
## alternate feet on successive steps, and turning in place is instant.
## Sheets come from PixelArt.character(look): columns idle, walk 1-4, run 1-4; rows
## down, up, left, right; 16x32 frames standing on the tile's bottom centre.

signal stepped(tile: Vector2i)

const DIR := {"down": Vector2i(0, 1), "up": Vector2i(0, -1), "left": Vector2i(-1, 0), "right": Vector2i(1, 0)}

var world: TileWorld
var look: Dictionary = {}
var sheet_id := ""
var tile := Vector2i.ZERO
## Facing as a unit vector (Vector2 so saves and the HUD treat it like the 2D player).
var facing := Vector2(0, 1)
var walk_time := 0.24
var run_time := 0.13

var sprite: Sprite2D
var _moving := false
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _t := 0.0
var _dur := 0.24
var _running := false
var _foot := 0
var _bump := 0.0


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = PixelArt.character(look, sheet_id)
	sprite.hframes = PixelArt.COLS
	sprite.vframes = 4
	sprite.centered = false
	sprite.offset = Vector2(-8, -31)
	add_child(sprite)
	if world != null:
		tile = world.tile_of(position)
		position = world.foot(tile)
		world.claim(tile, self)
	_pose()


func place(t: Vector2i, face: String = "down") -> void:
	if world != null and is_inside_tree():
		world.release(tile, self)
	tile = t
	facing = Vector2(DIR.get(face, Vector2i(0, 1)))
	_moving = false
	if world != null:
		position = world.foot(t)
		if is_inside_tree():
			world.claim(t, self)
	if sprite != null:
		_pose()


func is_moving() -> bool:
	return _moving


func face(d: Vector2i) -> void:
	facing = Vector2(d)
	_pose()


func dir_name() -> String:
	var d := Vector2i(roundi(facing.x), roundi(facing.y))
	for k: String in DIR:
		if DIR[k] == d:
			return k
	return "down"


## Begin a step in direction d. Returns false (and turns to face it) if blocked.
func try_step(d: Vector2i, run := false) -> bool:
	facing = Vector2(d)
	var next := tile + d
	if world == null or not world.can_enter(next, self):
		_pose()
		return false
	world.claim(next, self)
	_from = position
	_to = world.foot(next)
	_t = 0.0
	_dur = run_time if run else walk_time
	_running = run
	_moving = true
	_foot = (_foot + 1) % 2
	return true


func _process(delta: float) -> void:
	if _bump > 0.0:
		_bump -= delta
	if not _moving:
		return
	_t += delta / _dur
	if _t >= 1.0:
		world.release(tile, self)
		tile = world.tile_of(_to)
		position = _to
		_moving = false
		_pose()
		stepped.emit(tile)
		_on_arrived()
		return
	position = _from.lerp(_to, _t)
	_pose()


## Override: called when a step completes (doors, chaining).
func _on_arrived() -> void:
	pass


func _pose() -> void:
	if sprite == null:
		return
	var row: int = ["down", "up", "left", "right"].find(dir_name())
	var col := 0
	if _moving:
		# two frames per step, alternating feet: contact then passing
		var half := 0 if _t < 0.5 else 1
		col = (5 if _running else 1) + _foot * 2 + half
	elif _bump > 0.0:
		col = 1 + _foot * 2
	sprite.frame = row * PixelArt.COLS + col

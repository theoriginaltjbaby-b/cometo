class_name Person2D
extends Node2D
## A character in a Map2D drawn from a baked sheet (tools/bake_2d.gd): 8 directions,
## columns idle, 8 walk frames, 8 run frames. Stands in ground space; the sprite is
## lifted by the ground height. Optionally walks a loop of points (townsfolk) and can
## be talked to (make_talkable).

const CELL := Vector2i(32, 42)
const FEET := 35

var sheet: Texture2D
var map: Map2D
var points := PackedVector2Array()
var facing := Vector2(0, 1)
var speed := 1.1
var interactable: Interactable

var visual: Node2D
var _sprite: Sprite2D
var _phase := 0.0
var _height := 0.0
var _i := 0
var _wait := 0.0


func _ready() -> void:
	visual = Node2D.new()
	add_child(visual)
	var shadow := Shadow.new()
	visual.add_child(shadow)
	_sprite = Sprite2D.new()
	_sprite.texture = sheet
	_sprite.hframes = 17
	_sprite.vframes = 8
	_sprite.centered = false
	_sprite.offset = Vector2(-CELL.x * 0.5, -FEET)
	visual.add_child(_sprite)
	if not points.is_empty():
		position = points[0]
	_height = map.height_at(position) if map != null else 0.0
	_wait = randf_range(0.0, 3.0)
	show_pose(false, false, 0.0)


func make_talkable(display_name: String, dialogue_id: String) -> void:
	interactable = Interactable.new()
	interactable.prompt = "Talk"
	interactable.label = display_name
	interactable.dialogue_id = dialogue_id
	interactable.radius = 18.0
	add_child(interactable)
	interactable.interacted.connect(func(by: Node2D) -> void:
		var d := by.position - position
		if d.length() > 0.5:
			facing = d.normalized()
			show_pose(false, false, 0.0))


## Pick the frame for the facing and gait; delta advances the cycle.
func show_pose(moving: bool, running: bool, delta: float) -> void:
	var d := posmod(roundi(facing.angle() / (TAU / 8.0)), 8)
	var col := 0
	if moving:
		_phase += delta * (14.5 if running else 10.0)
		var f := posmod(int(floor(_phase / (TAU / 8.0))), 8)
		col = (9 if running else 1) + f
	else:
		_phase = 0.0
	_sprite.frame = d * 17 + col


func _process(delta: float) -> void:
	if map != null:
		var h := map.height_at(position)
		if map.is_ground(h):
			_height = lerpf(_height, h, 1.0 - exp(-20.0 * delta))
	visual.position = Vector2(0, -roundf(_height * map.S)) if map != null else Vector2.ZERO
	if points.size() < 2 or Dialogue.active:
		return
	if _wait > 0.0:
		_wait -= delta
		show_pose(false, false, delta)
		return
	var target := points[(_i + 1) % points.size()]
	var to := target - position
	if to.length() < 1.0:
		_i = (_i + 1) % points.size()
		_wait = randf_range(1.5, 5.0)
		return
	facing = to.normalized()
	position += facing * minf(speed * map.S * delta, to.length())
	show_pose(true, false, delta)


## Soft oval under the feet.
class Shadow:
	extends Node2D

	func _draw() -> void:
		draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, 7.0, Color(0.02, 0.02, 0.05, 0.35))
		draw_circle(Vector2.ZERO, 5.0, Color(0.02, 0.02, 0.05, 0.25))

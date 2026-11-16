class_name InteriorMap3D
extends MapBuilder3D
## Base for interiors in the Pokemon manner: a single room (or a few) entered through
## a door on the overworld, drawn as a cut-away box under the same fixed camera, with
## black around it. The front wall is left out so the camera sees in; a mat at the
## front edge leads back out. Lighting is indoor (EnvironmentController.indoor_look):
## the clock runs on, but sky, sun and weather do not reach inside.
##
## A subclass sets `exit_map` / `exit_spawn` (where the mat leads) and builds its room
## in _build() with room() and the MapBuilder3D kit.

## Where the exit mat leads.
@export var exit_map := "anjabi_town"
@export var exit_spawn := "default"


func _ready() -> void:
	indoor = true
	_materials()
	_environment()
	_build()
	var spawns := Node3D.new()
	spawns.name = "Spawns"
	add_child(spawns)
	var m := Marker3D.new()
	m.name = "default"
	m.position = entry_point()
	spawns.add_child(m)


## Override: the room's contents.
func _build() -> void:
	pass


## Override: where the player appears on entering (just inside the door).
func entry_point() -> Vector3:
	return Vector3(0, 0.05, 2.6)


## A room `size` (width, height, depth) centred on the origin, floor at y = 0, door in
## the middle of the open front (+Z). Walls are solid; the front has a low sill either
## side of the door so the room reads as closed.
func room(size: Vector3, floor_m: Material, wall_m: Material, door_w := 1.6) -> void:
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	slab(Vector3(-hx - 0.3, -0.4, -hz - 0.3), Vector3(hx + 0.3, 0.0, hz + 0.3), floor_m)
	box(Vector3(0, size.y * 0.5, -hz - 0.15), Vector3(size.x + 0.6, size.y, 0.3), wall_m)
	box(Vector3(-hx - 0.15, size.y * 0.5, 0), Vector3(0.3, size.y, size.z), wall_m)
	box(Vector3(hx + 0.15, size.y * 0.5, 0), Vector3(0.3, size.y, size.z), wall_m)
	# skirting along the walls
	box(Vector3(0, 0.08, -hz + 0.03), Vector3(size.x, 0.16, 0.06), M.timber, false)
	# low front sill either side of the door, and an invisible wall above it
	var side := (size.x - door_w) * 0.5
	for s: float in [-1.0, 1.0]:
		var cx := s * (door_w * 0.5 + side * 0.5)
		box(Vector3(cx, 0.25, hz + 0.15), Vector3(side, 0.5, 0.3), wall_m)
		blocker(Vector3(cx - side * 0.5, 0, hz), Vector3(cx + side * 0.5, 3, hz + 0.3))
	# the door mat and the way out
	box(Vector3(0, 0.01, hz - 0.35), Vector3(door_w * 0.8, 0.02, 0.6), M.canvas, false)
	blocker(Vector3(-door_w * 0.5, 0, hz + 0.8), Vector3(door_w * 0.5, 3, hz + 1.1))
	var out := MapExit3D.new()
	out.name = "ExitMat"
	out.prompt = "Leave"
	out.label = display_name.get_slice("·", display_name.get_slice_count("·") - 1).strip_edges().capitalize()
	out.radius = 1.0
	out.target_map = exit_map
	out.target_spawn = exit_spawn
	out.position = Vector3(0, 0.6, hz - 0.2)
	add_child(out)


## A hanging lamp: a small lit shade and a warm light under the ceiling.
func ceiling_lamp(at: Vector3) -> void:
	box(at, Vector3(0.5, 0.18, 0.5), M.lamp, false)
	warm_light(at + Vector3(0, -0.4, 0), 2.2, 7.0)

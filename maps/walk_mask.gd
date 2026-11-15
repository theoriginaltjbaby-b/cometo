class_name WalkMask
extends Node2D
## Walkable area stored as a BitMap, for maps laid out from a painted plan
## rather than from collision bodies. `pixel_size` is world pixels per mask pixel.

@export var mask: BitMap
@export var pixel_size := 2.0


func is_walkable(world: Vector2) -> bool:
	if mask == null:
		return true
	var p := Vector2i(((world - global_position) / pixel_size).floor())
	var s := mask.get_size()
	if p.x < 0 or p.y < 0 or p.x >= s.x or p.y >= s.y:
		return false
	return mask.get_bitv(p)


func nearest_walkable(world: Vector2, max_radius: float = 240.0) -> Vector2:
	if is_walkable(world):
		return world
	var r := pixel_size
	while r <= max_radius:
		for i in 16:
			var p := world + Vector2.from_angle(TAU * i / 16.0) * r
			if is_walkable(p):
				return p
		r += pixel_size
	return world

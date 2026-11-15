class_name GameMap3D
extends Node3D
## Base for 3D locations. Mirrors GameMap: needs an "Entities" child (the player
## is added there) and Marker3D spawn points under "Spawns".

@export var map_id := ""
@export var display_name := ""

## Set by Main once the player has been placed.
var player: Node3D

@onready var entities: Node3D = $Entities


func spawn_position(spawn: String) -> Vector3:
	var m := get_node_or_null("Spawns/" + spawn) as Node3D
	if m == null:
		m = get_node_or_null("Spawns/default") as Node3D
	return m.global_position if m != null else Vector3.ZERO

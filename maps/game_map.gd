class_name GameMap
extends Node2D
## Base for every walkable location. A map scene needs an "Entities" child
## (y-sorted; the player is added there) and Marker2D spawn points under "Spawns".

@export var map_id := ""
@export var display_name := ""
@export var bounds := Rect2(0, 0, 960, 704)

## Set by Main once the player has been placed.
var player: Node2D

@onready var entities: Node2D = $Entities


func spawn_position(spawn: String) -> Vector2:
	var m := get_node_or_null("Spawns/" + spawn) as Node2D
	if m == null:
		m = get_node_or_null("Spawns/default") as Node2D
	return m.global_position if m != null else bounds.get_center()

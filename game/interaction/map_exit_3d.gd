class_name MapExit3D
extends Interactable3D
## An interactable that travels to another map (2D or 3D).

@export var target_map := ""
@export var target_spawn := "default"


func interact(by: Node3D) -> void:
	interacted.emit(by)
	GameState.travel_requested.emit(target_map, target_spawn)

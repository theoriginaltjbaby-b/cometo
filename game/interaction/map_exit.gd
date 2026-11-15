class_name MapExit
extends Interactable
## An interactable that travels to another map.

@export var target_map := ""
@export var target_spawn := "default"


func interact(by: Node2D) -> void:
	interacted.emit(by)
	GameState.travel_requested.emit(target_map, target_spawn)

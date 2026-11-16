class_name Interactable
extends Area2D
## Reusable "the player can do something here" component. Drop it on anything.
## Either set dialogue_id (examine text and conversations are both dialogue data)
## or connect to `interacted` from a parent script.

signal interacted(by: Node2D)

@export var prompt := "Look"
@export var label := ""
@export var dialogue_id := ""
@export var radius := 14.0
## GameState condition; the interactable is ignored while it is false.
@export var enabled_if: Dictionary = {}

var enabled := true


func _ready() -> void:
	add_to_group(&"interactables_2d")
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	if get_child_count() == 0:
		var shape := CircleShape2D.new()
		shape.radius = radius
		var cs := CollisionShape2D.new()
		cs.shape = shape
		add_child(cs)


func is_available() -> bool:
	return enabled and GameState.check(enabled_if)


func interact(by: Node2D) -> void:
	interacted.emit(by)
	if dialogue_id != "":
		Dialogue.start(dialogue_id)

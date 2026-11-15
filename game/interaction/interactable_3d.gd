class_name Interactable3D
extends Area3D
## 3D twin of Interactable: same fields, same API (prompt, label, dialogue_id,
## enabled_if, is_available, interact), so the HUD and Dialogue treat both alike.

signal interacted(by: Node3D)

@export var prompt := "Look"
@export var label := ""
@export var dialogue_id := ""
@export var radius := 1.2
## GameState condition; the interactable is ignored while it is false.
@export var enabled_if: Dictionary = {}

var enabled := true


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	if get_child_count() == 0:
		var shape := SphereShape3D.new()
		shape.radius = radius
		var cs := CollisionShape3D.new()
		cs.shape = shape
		add_child(cs)


func is_available() -> bool:
	return enabled and GameState.check(enabled_if)


func interact(by: Node3D) -> void:
	interacted.emit(by)
	if dialogue_id != "":
		Dialogue.start(dialogue_id)

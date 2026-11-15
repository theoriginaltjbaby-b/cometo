class_name Npc3D
extends StaticBody3D
## A person standing in a 3D map who can be talked to. Same data as Npc
## (display_name, dialogue_id, colours); turns to face whoever speaks to them.

@export var display_name := "Someone"
@export var dialogue_id := ""
@export var coat := Color(0.35, 0.4, 0.45)
@export var accent := Color(0.7, 0.45, 0.2)
@export var skin := Color(0.78, 0.6, 0.48)
@export var hood := false
## Facing in degrees around Y; 0 faces north, 180 faces south (toward the camera).
@export var yaw_deg := 180.0
## Figure3D look options (hair, hat, long_coat, apron, satchel, hair_color).
@export var look: Dictionary = {}

var figure: Figure3D
var interactable: Interactable3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.6
	cs.shape = cap
	cs.position.y = 0.8
	add_child(cs)
	figure = Figure3D.new()
	figure.coat = coat
	figure.accent = accent
	figure.skin = skin
	figure.hood = hood
	figure.configure(look)
	figure.rotation.y = deg_to_rad(yaw_deg)
	add_child(figure)
	interactable = Interactable3D.new()
	interactable.label = display_name
	interactable.prompt = "Talk"
	interactable.dialogue_id = dialogue_id
	interactable.radius = 1.0
	interactable.position.y = 0.8
	add_child(interactable)
	interactable.interacted.connect(_on_interacted)


func _on_interacted(by: Node3D) -> void:
	var d := by.global_position - global_position
	d.y = 0.0
	if d.length() > 0.01:
		create_tween().tween_property(figure, "rotation:y", atan2(-d.x, -d.z), 0.2)

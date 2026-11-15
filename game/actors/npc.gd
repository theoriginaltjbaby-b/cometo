class_name Npc
extends StaticBody2D
## A person who stands somewhere and can be talked to. Routines, schedules and
## relationships are future work; they belong here, not in dialogue data.

@export var display_name := "Someone"
@export var dialogue_id := ""
@export var coat := Color(0.35, 0.4, 0.45)
@export var accent := Color(0.7, 0.45, 0.2)
@export var skin := Color(0.78, 0.6, 0.48)
@export var hood := false
@export var facing := Vector2.DOWN

@onready var sprite: CharSprite = $Sprite
@onready var interactable: Interactable = $Interactable


func _ready() -> void:
	sprite.coat = coat
	sprite.accent = accent
	sprite.skin = skin
	sprite.hood = hood
	sprite.set_motion(facing, false)
	interactable.label = display_name
	interactable.prompt = "Talk"
	interactable.dialogue_id = dialogue_id
	interactable.interacted.connect(_on_interacted)


func _on_interacted(by: Node2D) -> void:
	sprite.set_motion((by.global_position - global_position).normalized(), false)

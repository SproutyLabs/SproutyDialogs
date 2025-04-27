@tool
extends Node2D

@export_enum("uno", "dos", "tres") var portrait_type: int
@export_range(0, 20) var portrait_range: int

@export_file("*.png", "*.jpg") var portrait_image: String
@export_enum("happy", "sad", "none") var portrait_expression: String

@export var portrait_color: Color = Color(1, 1, 1, 1)
@export var portrait_mirror: bool

@export var protrait_node: Node
@export var portrait_array: Array
@export var predefined_array: Array = [1, true, [2, false, [3, true]]]
#@export var portrait_dict: Dictionary

func update_portrait() -> void:
	# This function is called when the portrait is instantiated or changed.
	# It should be overridden by subclasses to implement specific behavior.
	if portrait_image != "" and FileAccess.file_exists(portrait_image):
		$Sprite2D.texture = load(portrait_image)
	$Sprite2D.modulate = portrait_color
	$Sprite2D.flip_h = portrait_mirror
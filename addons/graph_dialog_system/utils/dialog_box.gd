@tool
@icon("res://addons/graph_dialog_system/icons/icon.svg")
class_name DialogBox
extends Panel

@export var dialog : String
@export var dialog_text_label : RichTextLabel
@export var continue_indicator : TextureRect

@export var type_time : float

func play_dialog(text : String = dialog) -> void:
	print("Playing dialog...")
	pass

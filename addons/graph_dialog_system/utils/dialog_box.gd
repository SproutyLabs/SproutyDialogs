@tool
@icon("res://addons/graph_dialog_system/icons/icon.svg")
class_name DialogBox
extends Panel

@export var name_text : RichTextLabel
@export var dialog_text : RichTextLabel
@export var continue_indicator : Control

func play_dialogue(char : String , text : String) -> void:
	name_text.text = char
	dialog_text.text = text
	print(char + " : " + text)

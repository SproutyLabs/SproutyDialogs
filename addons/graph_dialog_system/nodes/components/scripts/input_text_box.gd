@tool
extends HBoxContainer

@onready var text_box = $TextEdit

var text_editor : Panel

func _ready():
	text_editor = find_parent("Main").get_node("%Workspace/%TextEditor")

func _on_expand_button_pressed() -> void:
	# Open the extended window to edit text
	text_editor.edited_text_box = text_box
	text_editor.show_text_editor()

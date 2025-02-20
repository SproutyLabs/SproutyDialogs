@tool
extends HBoxContainer

@onready var text_box = $TextEdit

var text_editor : Panel

func _ready():
	text_editor = find_parent("Main").get_node("%Workspace/TextEditor")

func get_text() -> String:
	return text_box.text

func set_text(text : String) -> void:
	text_box.text = text

func _on_expand_button_pressed() -> void:
	# Open the extended window to edit text
	text_editor.edited_text_box = text_box
	text_editor.show_text_editor()

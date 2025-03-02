@tool
extends HBoxContainer

## -----------------------------------------------------------------------------
## Dialog text box component
##
## Component to write and edit dialog text, and allow the user to expand the
## text opening the text editor window.
## -----------------------------------------------------------------------------

## Input text box
@onready var text_box = $TextEdit

## Text editor panel
var text_editor: Panel


func _ready():
	var editor_main = find_parent("Main")
	if editor_main: # Get the text editor panel from the main node
		text_editor = editor_main.get_node("%Workspace/TextEditor")


## Get the text from the text box
func get_text() -> String:
	return text_box.text


## Set the text to the text box
func set_text(text: String) -> void:
	text_box.text = text


## Open the text editor window
func _on_expand_button_pressed() -> void:
	text_editor.edited_text_box = text_box
	text_editor.show_text_editor()

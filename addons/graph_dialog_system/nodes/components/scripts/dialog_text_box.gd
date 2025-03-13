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
	# Find the Graph and get the text editor reference
	var graph = find_parent("Graph")
	if graph: text_editor = graph.text_editor


## Get the text from the text box
func get_text() -> String:
	return text_box.text


## Set the text to the text box
func set_text(text: String) -> void:
	text_box.text = text


## Open the text editor window
func _on_expand_button_pressed() -> void:
	text_editor.show_text_editor(text_box)

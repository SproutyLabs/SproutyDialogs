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
## Expand button
@onready var expand_button = $ExpandButton


func _ready():
	expand_button.icon = get_theme_icon("DistractionFree", "EditorIcons")


## Get the text from the text box
func get_text() -> String:
	return text_box.text


## Set the text to the text box
func set_text(text: String) -> void:
	text_box.text = text


## Open the text editor window
func _on_expand_button_pressed() -> void:
	find_parent("Graph").text_editor.show_text_editor(text_box)

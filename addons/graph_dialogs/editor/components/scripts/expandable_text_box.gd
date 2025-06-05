@tool
extends HBoxContainer

## -----------------------------------------------------------------------------
## Expandable text box component
##
## Component to write and edit dialog text allowing the user to expand the
## text opening a text editor window.
## -----------------------------------------------------------------------------

## Emitted when pressing the expand button to open the text editor
signal open_text_editor

## Input text box
@onready var text_box = $TextEdit
## Expand button
@onready var expand_button = $ExpandButton


func _ready():
	expand_button.pressed.connect(open_text_editor.emit)
	expand_button.icon = get_theme_icon("DistractionFree", "EditorIcons")


## Get the text from the text box
func get_text() -> String:
	return text_box.text


## Set the text to the text box
func set_text(text: String) -> void:
	text_box.text = text

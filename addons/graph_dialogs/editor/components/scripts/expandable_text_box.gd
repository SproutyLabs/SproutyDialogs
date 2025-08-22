@tool
class_name GraphDialogsExpandableTextBox
extends HBoxContainer

# -----------------------------------------------------------------------------
## Expandable text box component
##
## Component to write and edit dialog text allowing the user to expand the
## text opening a text editor window.
# -----------------------------------------------------------------------------

## Emitted when the text in the text box changes
signal text_changed(text: String)
## Emitted when pressing the expand button to open the text editor
signal open_text_editor(text_box: TextEdit)

## Input text box
@onready var _text_box: TextEdit = $TextEdit


func _ready():
	_text_box.text_changed.connect(text_changed.emit)
	$ExpandButton.pressed.connect(open_text_editor.emit.bind(_text_box))
	$ExpandButton.icon = get_theme_icon("DistractionFree", "EditorIcons")


## Get the text from the text box
func get_text() -> String:
	return _text_box.text


## Set the text to the text box
func set_text(text: String) -> void:
	_text_box.text = text

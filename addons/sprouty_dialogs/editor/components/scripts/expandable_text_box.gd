@tool
class_name EditorSproutyDialogsExpandableTextBox
extends HBoxContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs Expandable Text Box Component
# -----------------------------------------------------------------------------
## Component that extends a text box with an expand button to open a larger 
## text editor.
# -----------------------------------------------------------------------------

## Emitted when the text in the text box changes
signal text_changed(text: String)
## Emitted when pressing the expand button to open the text editor
signal open_text_editor(text_box: TextEdit)
## Emitted when the text in the text editor is updated
signal update_text_editor(text_box: TextEdit)
## Emitted when the text box loses focus
signal text_box_focus_exited()

## Input text box
@onready var _text_box: TextEdit = $TextEdit


func _ready():
	_text_box.text_changed.connect(text_changed.emit)
	_text_box.focus_exited.connect(text_box_focus_exited.emit)
	_text_box.focus_entered.connect(update_text_editor.emit.bind(_text_box))
	$ExpandButton.pressed.connect(open_text_editor.emit.bind(_text_box))
	$ExpandButton.icon = get_theme_icon("DistractionFree", "EditorIcons")


## Returns the text from the text box
func get_text() -> String:
	return _text_box.text


## Set the text to the text box
func set_text(text: String) -> void:
	_text_box.text = text

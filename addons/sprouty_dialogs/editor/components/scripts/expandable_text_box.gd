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

const MAX_VISIBLE_LINES := 3
const EXTRA_Y_PADDING := 8

## Input text box
@onready var _text_box: TextEdit = $TextEdit


func _ready():
	_text_box.text_changed.connect(_on_text_changed_internal)
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
	_update_text_box_size()


## Update the size of the text box by the line count
func _update_text_box_size() -> void:
	var lines := mini(_text_box.get_total_visible_line_count(), MAX_VISIBLE_LINES)
	var h := lines * _text_box.get_line_height() + EXTRA_Y_PADDING
	_text_box.custom_minimum_size.y = h
	custom_minimum_size.y = h


## Handle the text changed signal
func _on_text_changed_internal(_arg: Variant = null) -> void:
	text_changed.emit(_text_box.text)
	_update_text_box_size()
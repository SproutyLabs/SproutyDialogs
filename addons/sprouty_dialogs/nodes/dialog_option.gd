@icon("res://addons/sprouty_dialogs/editor/icons/nodes/dialog_option.svg")
class_name DialogOption
extends Button

# -----------------------------------------------------------------------------
# Sprouty Dialogs Dialog Option
# ------------------------------------------------------------------------------
## Component that render a dialog option in a [DialogBox] from Sprouty Dialogs plugin.
##
## It extends the Button class to provide a clickable option in the dialog.
# -----------------------------------------------------------------------------

## Emitted when the option is selected.
signal option_selected(option_index: int)

## Label to display the option text (Optional).
## If you want to use a custom label, assign it to this variable.
## It should be a child of this node.
@export var text_display: Label
## RichTextLabel to display the option text (Optional).
## If you want to use a rich text label, assign it to this variable.
## It should be a child of this node.
@export var rich_text_display: RichTextLabel

## Index of the option in the dialog
var option_index: int = 0


func _ready() -> void:
	# Connect the button pressed signal
	pressed.connect(_on_option_selected)
	visible = false


## Return the text of the option
func get_text() -> String:
	if text_display:
		return text_display.text
	elif rich_text_display:
		return rich_text_display.text
	return self.text


## Set the text of the option
func set_text(text: String) -> void:
	if text_display:
		text_display.text = text
	elif rich_text_display:
		rich_text_display.text = text
	else:
		self.text = text


## Handle the option selection
func _on_option_selected() -> void:
	option_selected.emit(option_index)

@tool
extends Container

# -----------------------------------------------------------------------------
# Variables Panel
# -----------------------------------------------------------------------------
## This panel allows the user to manage variables in the Sprouty Dialogs editor.
## It provides functionality to add, remove, rename, filter and save variables.
# -----------------------------------------------------------------------------

## Variables editor
@onready var _variables_editor: Control = $VariablesEditor
## Text editor for edit string variables
@onready var _text_editor: Control = $TextEditor


func _ready():
	# Connect signals
	_variables_editor.open_text_editor.connect(_on_open_text_editor)
	_variables_editor.update_text_editor.connect(_text_editor.update_text_editor)
	_text_editor.hide()


## Handle the opening of the text editor
## Needs a TextEdit or LineEdit with the text to edit
func _on_open_text_editor(text_box: Variant) -> void:
	_text_editor.show_text_editor(text_box)
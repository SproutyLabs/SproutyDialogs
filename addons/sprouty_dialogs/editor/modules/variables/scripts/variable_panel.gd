@tool
extends Container

# -----------------------------------------------------------------------------
# Variable Panel
# -----------------------------------------------------------------------------
## This panel handles the variable editor and text editor for manage the
## variables in the Sprouty Dialogs editor.
# -----------------------------------------------------------------------------

## Variable editor
@onready var _variable_editor: EditorSproutyDialogsVariableEditor = $VariableEditor
## Text editor for edit string variables
@onready var _text_editor: EditorSproutyDialogsTextEditor = $TextEditor

## Set the UndoRedo manager in the variable editor
var undo_redo: EditorUndoRedoManager:
	set(value):
		undo_redo = value
		_variable_editor.undo_redo = value


func _ready():
	# Connect signals
	_variable_editor.open_text_editor.connect(_on_open_text_editor)
	_variable_editor.update_text_editor.connect(_text_editor.update_text_editor)
	_text_editor.hide()


## Handle the opening of the text editor
## Needs a TextEdit or LineEdit with the text to edit
func _on_open_text_editor(text_box: Variant) -> void:
	_text_editor.show_text_editor(text_box)
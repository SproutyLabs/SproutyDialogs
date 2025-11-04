@tool
extends Container

# -----------------------------------------------------------------------------
# Variables Panel
# -----------------------------------------------------------------------------
## This panel handles the variables editor and text editor for manage the
## variables in the Sprouty Dialogs editor.
# -----------------------------------------------------------------------------

## Variables editor
@onready var _variables_editor: EditorSproutyDialogsVariableEditor = $VariablesEditor
## Text editor for edit string variables
@onready var _text_editor: EditorSproutyDialogsTextEditor = $TextEditor

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready():
	# Connect signals
	_variables_editor.open_text_editor.connect(_on_open_text_editor)
	_variables_editor.update_text_editor.connect(_text_editor.update_text_editor)
	_text_editor.hide()


## Handle the opening of the text editor
## Needs a TextEdit or LineEdit with the text to edit
func _on_open_text_editor(text_box: Variant) -> void:
	_text_editor.show_text_editor(text_box)
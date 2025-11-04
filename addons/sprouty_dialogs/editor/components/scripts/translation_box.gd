@tool
class_name EditorSproutyDialogsTranslationBox
extends Container

# -----------------------------------------------------------------------------
# Sprouty Dialogs Translation Box Component
# -----------------------------------------------------------------------------
## Component to display a text box with header labels that indicates the 
## language and locale code of the translation.
##
## Needs a text box child node that can be a LineEdit, TextEdit or ExpandableTextBox.
# -----------------------------------------------------------------------------

## Emitted when the translation box is modified
signal modified(modified: bool)
## Emitted when pressing the expand button to open the text editor
signal open_text_editor(text_box: TextEdit)
## Emitted when the text box focus is changed while the text editor is open
signal update_text_editor(text_box: TextEdit)

## Language label of the translation
@onready var _language_label: Label = $Header/LanguageLabel
## Locale code label of the translation
@onready var _code_label: Label = $Header/CodeLabel
## Input text box
@onready var _text_box: Control = $TextBox

## Locale code of the translation
var _locale_code: String = ""

## Current text of the translation (for UndoRedo)
var _translation_text: String = ""
## Flag to check if the text was modified (for UndoRedo)
var _text_modified: bool = false

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready():
	if _text_box is EditorSproutyDialogsExpandableTextBox:
		_text_box.open_text_editor.connect(open_text_editor.emit)
		_text_box.update_text_editor.connect(update_text_editor.emit)
		_text_box.text_changed.connect(_on_expandable_box_text_changed)
		_text_box.text_box_focus_exited.connect(_on_text_focus_exited)
	else:
		_text_box.text_changed.connect(_on_text_changed)
		_text_box.mouse_exited.connect(_on_text_focus_exited)


## Returns the text from the text box
func get_text() -> String:
	if _text_box is EditorSproutyDialogsExpandableTextBox:
		return _text_box.get_text()
	else:
		return _text_box.text


## Set the text to the text box
func set_text(text: String) -> void:
	if _text_box is EditorSproutyDialogsExpandableTextBox:
		_text_box.set_text(text)
		_translation_text = text
	else:
		_text_box.text = text
		_translation_text = text


## Returns the locale code
func get_locale() -> String:
	return _locale_code


## Set the locale code and update the labels
func set_locale(locale: String) -> void:
	_locale_code = locale
	_code_label.text = "(" + locale + ")"
	_language_label.text = TranslationServer.get_locale_name(locale)
	_language_label.get_parent().tooltip_text = _language_label.text


## Handle the text changed signal from an ExpandableTextBox
func _on_expandable_box_text_changed(new_text: String = "") -> void:
	if _translation_text != _text_box.get_text():
		var temp = _translation_text
		_translation_text = _text_box.get_text()
		_text_modified = true
	
		# --- UndoRedo ---------------------------------------------------------
		undo_redo.create_action("Edit Translation Text (" + get_locale() + ")", 1)
		undo_redo.add_do_property(self, "_translation_text", _translation_text)
		undo_redo.add_do_method(_text_box, "set_text", _translation_text)
		undo_redo.add_undo_property(self, "_translation_text", temp)
		undo_redo.add_undo_method(_text_box, "set_text", temp)

		undo_redo.add_do_method(self, "emit_signal", "modified", true)
		undo_redo.add_undo_method(self, "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# ----------------------------------------------------------------------


## Handle the text box text changed signal
func _on_text_changed(new_text: String = "") -> void:
	if _translation_text != _text_box.text:
		var temp = _translation_text
		_translation_text = _text_box.text
		_text_modified = true
	
		# --- UndoRedo ---------------------------------------------------------
		undo_redo.create_action("Edit Translation Text (" + get_locale() + ")", 1)
		undo_redo.add_do_property(self, "_translation_text", _translation_text)
		undo_redo.add_do_property(_text_box, "text", _translation_text)
		undo_redo.add_undo_property(self, "_translation_text", temp)
		undo_redo.add_undo_property(_text_box, "text", temp)

		undo_redo.add_do_method(self, "emit_signal", "modified", true)
		undo_redo.add_undo_method(self, "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# ----------------------------------------------------------------------


## Handle the text box focus exited signal
func _on_text_focus_exited() -> void:
	if _text_modified:
		_text_modified = false
		modified.emit(true)
@tool
class_name GraphDialogsTranslationBox
extends Container

# -----------------------------------------------------------------------------
## Translation box
##
## Component to display a text box with header labels that indicates the 
## language and locale code of the translation.
##
## Needs a text box child node that can be a LineEdit, TextEdit or ExpandableTextBox.
# -----------------------------------------------------------------------------

## Emitted when the text in the text box changes
signal text_changed(text: String)
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


func _ready():
	if _text_box is GraphDialogsExpandableTextBox:
		_text_box.open_text_editor.connect(open_text_editor.emit)
		_text_box.update_text_editor.connect(update_text_editor.emit)
	_text_box.text_changed.connect(text_changed.emit)


## Get the text from the text box
func get_text() -> String:
	if _text_box is GraphDialogsExpandableTextBox:
		return _text_box.get_text()
	else:
		return _text_box.text


## Set the text to the text box
func set_text(text: String) -> void:
	if _text_box is GraphDialogsExpandableTextBox:
		_text_box.set_text(text)
	else:
		_text_box.text = text


## Get the locale code
func get_locale() -> String:
	return _locale_code


## Set the locale code and update the labels
func set_locale(locale: String) -> void:
	_locale_code = locale
	_code_label.text = "(" + locale + ")"
	_language_label.text = TranslationServer.get_locale_name(locale)

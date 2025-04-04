@tool
class_name GDialogsTranslationBox
extends Container

## -----------------------------------------------------------------------------
## Translation box
##
## Component to display a text box with header labels that indicates the 
## language and locale code of the translation.
##
## Needs a text box child node that can be a LineEdit or a TextEdit.
## -----------------------------------------------------------------------------

## Language label of the translation
@onready var language_label: Label = $Header/LanguageLabel
## Locale code label of the translation
@onready var code_label: Label = $Header/CodeLabel
## Input text box
@onready var text_box: Control = $TextBox

## Locale code of the translation
var locale_code: String = ""

## Get the text from the text box
func get_text() -> String:
	if text_box is LineEdit:
		return text_box.text
	else: return text_box.get_text()


## Set the text to the text box
func set_text(text: String) -> void:
	if text_box is LineEdit:
		text_box.text = text
	else: text_box.set_text(text)


## Get the locale code
func get_locale() -> String:
	return locale_code


## Set the locale code and update the labels
func set_locale(locale: String) -> void:
	locale_code = locale
	code_label.text = "(" + locale + ")"
	language_label.text = TranslationServer.get_locale_name(locale)

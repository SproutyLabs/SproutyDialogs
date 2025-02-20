@tool
extends VBoxContainer

@onready var language_label : Label = $Header/LanguageLabel
@onready var code_label : Label = $Header/CodeLabel
@onready var text_box : HBoxContainer = $DialogTextBox

var locale_code : String = ""

func get_text() -> String:
	return text_box.get_text()

func set_text(text : String) -> void:
	text_box.set_text(text)

func get_locale() -> String:
	return locale_code

func set_locale(locale : String) -> void:
	# Set locale on labels
	locale_code = locale
	code_label.text = "(" + locale + ")"
	language_label.text = TranslationServer.get_locale_name(locale)

@tool
extends HSplitContainer

## -----------------------------------------------------------------------------
## Character Panel
## 
## This module is responsible for the character editing panel in the editor.
## It allows the user to edit character data, including the character's name,
## description, dialogue box, portraits and typing sounds.
## -----------------------------------------------------------------------------

## Triggered when something is modified
signal modified

## Label with the key name of the character
@onready var _key_name_label: Label = %KeyNameLabel
## Label with the default locale for display name
@onready var _name_default_locale_label: Label = %NameDefaultLocaleLabel
## Display name text input field in default locale
@onready var _name_default_locale_field: LineEdit = %NameDefaultLocaleField
## Translation container for display name
@onready var _name_translations_container: VBoxContainer = %NameTranslationsContainer
## Description text input field
@onready var _description_field: TextEdit = %DescriptionField

## Default locale for dialog text
var default_locale: String = ""


func _ready() -> void:
	_set_translation_text_boxes()
	GDialogsTranslationManager.translation_settings.connect(
			"locales_changed", _on_locales_changed
		)
	GDialogsTranslationManager.translation_settings.connect(
			"default_locale_changed", _on_locales_changed
		)


## Get the character data from the editor
func get_character_data() -> Dictionary:
	var data = {
		"character_data": {
			"key_name": _key_name_label.text,
			"display_name": {_key_name_label.text: get_name_translations()},
			"description": _description_field.text,
			"dialog_box": "",
			"typing_sounds": {},
			"portraits": {}
		}
	}
	return data


## Load the character data into the editor
func load_character(data: Dictionary, name_data: Dictionary) -> void:
	_key_name_label.text = data.key_name.to_pascal_case()
	var name_translations = name_data[data.key_name]

	# Character name and its translations
	_set_translation_text_boxes()
	_name_default_locale_field.text = name_translations[default_locale]
	_name_translations_container.load_translations_text(name_translations)

	_description_field.text = data.description


#region === Character Name Translation =========================================

## Get character name translations
func get_name_translations() -> Dictionary:
	var translations = {}
	translations[default_locale] = _name_default_locale_field.text
	translations.merge(_name_translations_container.get_translations_text())
	return translations


## Load character name translations
func load_name_translations(translations: Dictionary) -> void:
	_name_default_locale_field = translations[default_locale]
	_name_translations_container.load_translations_text(translations)


## Set character name translations text boxes
func _set_translation_text_boxes() -> void:
	default_locale = GDialogsTranslationManager.default_locale
	_name_default_locale_label.text = "(" + default_locale + ")"
	_name_default_locale_field.text = ""
	_name_translations_container.set_translation_boxes(
			GDialogsTranslationManager.locales.filter(
				func(locale): return locale != default_locale
			)
		)


## Update name translations text boxes when locales change
func _on_locales_changed() -> void:
	var translations = get_name_translations()
	_set_translation_text_boxes()
	load_name_translations(translations)

#endregion
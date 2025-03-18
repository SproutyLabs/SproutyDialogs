@tool
extends HSplitContainer

## Label with the key name of the character
@onready var _key_name_label: Label = %KeyNameLabel
## Label with the default locale for display name
@onready var _name_default_locale_label: Label = %NameDefaultLocaleLabel
## Display name text input field in default locale
@onready var _name_default_locale_field: LineEdit = %NameDefaultLocaleField
## Description text input field
@onready var _description_field: TextEdit = %DescriptionField


## Get the character data from the editor
func get_character_data() -> Dictionary:
	# TODO: save names on csv
	var data = {
		"character_data": {
			"key_name": _key_name_label.text,
			"description": _description_field.text,
			"dialog_box": "",
			"typing_sounds": {},
			"portraits": {}
		}
	}
	return data


## Load the character data into the editor
func load_character(data: Dictionary) -> void:
	_key_name_label.text = data.key_name
	_name_default_locale_label.text = GDialogsTranslationManager.default_locale
	# TODO: load names from csv
	_description_field.text = data.description
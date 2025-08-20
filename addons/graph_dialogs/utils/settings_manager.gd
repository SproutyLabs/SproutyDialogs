@tool
class_name GraphDialogsSettings
extends Node

## -----------------------------------------------------------------------------
## Settings Manager
##
## This class manages the settings for the Graph Dialogs plugin.
## It provides methods to get, set, and check settings values.
## -----------------------------------------------------------------------------

## Default dialog box path to load if no dialog box is specified.
const DEFAULT_BOX_PATH = "res://addons/graph_dialogs/objects/defaults/default_dialog_box.tscn"

## Settings paths used in the plugin.
## This dictionary maps setting names to their paths in the project settings.
static var _settings_paths: Dictionary = {
	# --- General settings -----------------------------------------------------
	"continue_input_action": "graph_dialogs/general/continue_input_action",
	"default_dialog_box": "graph_dialogs/general/default_dialog_box",
	"dialog_box_canvas_layer": "graph_dialogs/general/dialog_box_canvas_layer",
	"portraits_canvas_layer": "graph_dialogs/general/portraits_canvas_layer",
	
	# --- Text settings --------------------------------------------------------
	"default_typing_speed": "graph_dialogs/text/default_typing_speed",
	"open_url_on_meta_tag_click": "graph_dialogs/text/open_url_on_meta_tag_click",

	# Text/Display settings
	"new_line_as_new_dialog": "graph_dialogs/text/display/new_line_as_new_dialog",
	"split_dialog_by_max_characters": "graph_dialogs/text/display/split_dialog_by_max_characters",
	"max_characters": "graph_dialogs/text/display/max_characters",

	# Text/Skip settings
	"allow_skip_text_reveal": "graph_dialogs/text/skip/allow_skip_text_reveal",
	"can_skip_delay": "graph_dialogs/text/skip/can_skip_delay",
	"skip_continue_delay": "graph_dialogs/text/skip/continue_delay",
	
	# -- Translation settings --------------------------------------------------
	"enable_translations": "graph_dialogs/translation/enable_translations",
	"use_csv": "graph_dialogs/translation/csv_files/use_csv",
	"csv_translations_folder": "graph_dialogs/translation/csv_files/csv_translations_folder",

	# Translation/CSV files settings
	"translate_character_names": "graph_dialogs/translation/characters/translate_character_names",
	"use_csv_for_character_names": "graph_dialogs/translation/characters/use_csv_for_character_names",
	"character_names_csv": "graph_dialogs/translation/characters/character_names_csv",

	# Translation/Localization settings
	"default_locale": "graph_dialogs/translation/localization/default_locale",
	"testing_locale": "graph_dialogs/translation/localization/testing_locale",
	"locales": "graph_dialogs/translation/localization/locales",

	# -- Variable settings -----------------------------------------------------
	"variables": "graph_dialogs/variables/variables"
}


## Returns a setting value from the plugin settings.
## If the setting is not found, it returns null and prints an error message.
static func get_setting(setting_name: String) -> Variant:
	if ProjectSettings.has_setting(_settings_paths[setting_name]):
		return ProjectSettings.get_setting(_settings_paths[setting_name])
	else:
		printerr("[Graph Dialogs] Setting '" + setting_name + "' not found.")
		return null


## Sets a setting value in the plugin settings.
## If the setting is not found, it prints an error message.
static func set_setting(setting_name: String, value: Variant) -> void:
	if ProjectSettings.has_setting(_settings_paths[setting_name]):
		ProjectSettings.set_setting(_settings_paths[setting_name], value)
		ProjectSettings.save()
	else:
		printerr("[Graph Dialogs] Setting '" + setting_name + "' not found. Cannot set value.")


## Checks if a setting exists in the plugin settings.
static func has_setting(setting_name: String) -> bool:
	if not _settings_paths.has(setting_name):
		printerr("[Graph Dialogs] Setting '" + setting_name + "' does not exist in the plugin.")
		return false
	return ProjectSettings.has_setting(_settings_paths[setting_name])


## Initializes the default settings for the plugin.
## This method should be called when the plugin is first loaded or when the settings are reset.
static func initialize_default_settings() -> void:
	# General settings
	ProjectSettings.set_setting(_settings_paths["continue_input_action"],
			"dialogs_continue_action")
	ProjectSettings.set_setting(_settings_paths["default_dialog_box"],
			ResourceSaver.get_resource_id_for_path(DEFAULT_BOX_PATH))
	ProjectSettings.set_setting(_settings_paths["dialog_box_canvas_layer"], 2)
	ProjectSettings.set_setting(_settings_paths["portraits_canvas_layer"], 1)

	# Text settings
	ProjectSettings.set_setting(_settings_paths["default_typing_speed"], 0.05)
	ProjectSettings.set_setting(_settings_paths["new_line_as_new_dialog"], true)
	ProjectSettings.set_setting(_settings_paths["split_dialog_by_max_characters"], false)
	ProjectSettings.set_setting(_settings_paths["max_characters"], 0)
	ProjectSettings.set_setting(_settings_paths["allow_skip_text_reveal"], true)
	ProjectSettings.set_setting(_settings_paths["can_skip_delay"], 0.1)
	ProjectSettings.set_setting(_settings_paths["skip_continue_delay"], 0.1)
	ProjectSettings.set_setting(_settings_paths["open_url_on_meta_tag_click"], true)

	# Translation settings
	ProjectSettings.set_setting(_settings_paths["enable_translations"], false)
	ProjectSettings.set_setting(_settings_paths["use_csv"], false)
	ProjectSettings.set_setting(_settings_paths["csv_translations_folder"], "")
	ProjectSettings.set_setting(_settings_paths["translate_character_names"], false)
	ProjectSettings.set_setting(_settings_paths["use_csv_for_character_names"], false)
	ProjectSettings.set_setting(_settings_paths["character_names_csv"], "")

	# Set the editor locale as the default locale
	var settings = EditorInterface.get_editor_settings()
	var editor_lang = settings.get_setting("interface/editor/editor_language")
	ProjectSettings.set_setting(_settings_paths["default_locale"], editor_lang)
	ProjectSettings.set_setting(_settings_paths["testing_locale"], editor_lang)
	ProjectSettings.set_setting(_settings_paths["locales"], [editor_lang])

	# Variable settings
	ProjectSettings.set_setting(_settings_paths["variables"], {})
	ProjectSettings.save()

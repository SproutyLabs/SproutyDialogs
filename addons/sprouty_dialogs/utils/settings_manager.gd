@tool
class_name SproutyDialogsSettingsManager
extends RefCounted

# -----------------------------------------------------------------------------
# Sprouty Dialogs Settings Manager
# -----------------------------------------------------------------------------
## This class manages the settings for the Sprouty Dialogs plugin.
## It provides methods to get, set, check and reset settings.
# -----------------------------------------------------------------------------

## Default dialog box path to load if no dialog box is specified.
const DEFAULT_DIALOG_BOX_PATH = "res://addons/sprouty_dialogs/nodes/defaults/default_dialog_box.tscn"
## Default portrait scene path to load when creating a new portrait.
const DEFAULT_PORTRAIT_PATH = "res://addons/sprouty_dialogs/nodes/defaults/default_portrait.tscn"

## Settings paths used in the plugin.
## This dictionary maps setting names to their paths in the project settings.
static var _settings_paths: Dictionary = {
	# --- General settings -----------------------------------------------------
	"continue_input_action": {
		"path": "graph_dialogs/general/input/continue_input_action",
		"default": "dialogs_continue_action"
	},
	# Default scenes
	"default_dialog_box": {
		"path": "graph_dialogs/general/defaults/default_dialog_box",
		"default": ResourceSaver.get_resource_id_for_path(DEFAULT_DIALOG_BOX_PATH, true)
	},
	"default_portrait_scene": {
		"path": "graph_dialogs/general/defaults/default_portrait_scene",
		"default": ResourceSaver.get_resource_id_for_path(DEFAULT_PORTRAIT_PATH, true)
	},
	# Canvas layers
	"dialog_box_canvas_layer": {
		"path": "graph_dialogs/general/canvas/dialog_box_canvas_layer",
		"default": 2
	},
	"portraits_canvas_layer": {
		"path": "graph_dialogs/general/canvas/portraits_canvas_layer",
		"default": 1
	},
	# Custom event nodes
	"use_custom_event_nodes": {
		"path": "graph_dialogs/general/custom/use_custom_event_nodes",
		"default": false
	},
	"custom_event_nodes_folder": {
		"path": "graph_dialogs/general/custom/custom_event_nodes_folder",
		"default": ""
	},
	"custom_event_interpreter": {
		"path": "graph_dialogs/general/custom/custom_event_interpreter",
		"default": - 1
	},
	# --- Text settings --------------------------------------------------------
	"default_typing_speed": {
		"path": "graph_dialogs/text/default_typing_speed",
		"default": 0.05
	},
	"open_url_on_meta_tag_click": {
		"path": "graph_dialogs/text/open_url_on_meta_tag_click",
		"default": true
	},
	# Text/Display settings
	"new_line_as_new_dialog": {
		"path": "graph_dialogs/text/display/new_line_as_new_dialog",
		"default": true
	},
	"split_dialog_by_max_characters": {
		"path": "graph_dialogs/text/display/split_dialog_by_max_characters",
		"default": false
	},
	"max_characters": {
		"path": "graph_dialogs/text/display/max_characters",
		"default": 0
	},
	# Text/Skip settings
	"allow_skip_text_reveal": {
		"path": "graph_dialogs/text/skip/allow_skip_text_reveal",
		"default": true
	},
	"can_skip_delay": {
		"path": "graph_dialogs/text/skip/can_skip_delay",
		"default": 0.1
	},
	"skip_continue_delay": {
		"path": "graph_dialogs/text/skip/continue_delay",
		"default": 0.1
	},
	# -- Translation settings --------------------------------------------------
	"enable_translations": {
		"path": "graph_dialogs/translation/enable_translations",
		"default": false
	},
	# Translation/CSV files settings
	"use_csv_files": {
		"path": "graph_dialogs/translation/csv_files/use_csv_files",
		"default": false
	},
	"csv_translations_folder": {
		"path": "graph_dialogs/translation/csv_files/csv_translations_folder",
		"default": ""
	},
	"fallback_to_resource": {
		"path": "graph_dialogs/translation/csv_files/fallback_to_resource",
		"default": true
	},
	# Translation/Characters settings
	"translate_character_names": {
		"path": "graph_dialogs/translation/characters/translate_character_names",
		"default": false
	},
	"use_csv_for_character_names": {
		"path": "graph_dialogs/translation/characters/use_csv_for_character_names",
		"default": false
	},
	"character_names_csv": {
		"path": "graph_dialogs/translation/characters/character_names_csv",
		"default": - 1
	},
	# Translation/Localization settings
	"default_locale": {
		"path": "graph_dialogs/translation/localization/default_locale",
		"default": "en"
	},
	"testing_locale": {
		"path": "internationalization/locale/test",
		"default": ""
	},
	"locales": {
		"path": "graph_dialogs/translation/localization/locales",
		"default": ["en"]
	},
	# -- Variable settings -----------------------------------------------------
	"variables": {
		"path": "graph_dialogs/variables/variables",
		"default": {}
	},
	# -- Internal settings (not exposed in the UI) -----------------------------
	"play_dialog_path": {
		"path": "graph_dialogs/internal/play_dialog_path",
		"default": ""
	},
	"play_start_id": {
		"path": "graph_dialogs/internal/play_start_id",
		"default": ""
	}
}


## Returns a setting value from the plugin settings.
## If the setting is not found, it returns null and prints an error message.
static func get_setting(setting_name: String) -> Variant:
	if has_setting(setting_name):
		return ProjectSettings.get_setting(_settings_paths[setting_name]["path"])
	else:
		printerr("[Sprouty Dialogs] Setting '" + setting_name + "' not found.")
		return null


## Sets a setting value in the plugin settings.
## If the setting is not found, it prints an error message.
static func set_setting(setting_name: String, value: Variant) -> void:
	if has_setting(setting_name):
		ProjectSettings.set_setting(_settings_paths[setting_name]["path"], value)
		ProjectSettings.save()
	else:
		printerr("[Sprouty Dialogs] Setting '" + setting_name + "' not found. Cannot set value.")


## Checks if a setting exists in the plugin settings.
static func has_setting(setting_name: String) -> bool:
	if not _settings_paths.has(setting_name):
		printerr("[Sprouty Dialogs] Setting '" + setting_name + "' does not exist in the plugin.")
		return false
	return ProjectSettings.has_setting(_settings_paths[setting_name]["path"]) \
			or setting_name == "testing_locale" # Special case for testing_locale


## Returns the default value of a setting.
static func get_default_setting(setting_name: String) -> Variant:
	return _settings_paths[setting_name]["default"]


## Reset a setting to its default value.
static func reset_setting(setting_name: String) -> void:
	ProjectSettings.set_setting(
			_settings_paths[setting_name]["path"],
			_settings_paths[setting_name]["default"]
		)
	ProjectSettings.save()


## Initializes the default settings for the plugin.
## This method should be called when the plugin is first loaded or when the settings are reset.
static func initialize_default_settings() -> void:
	for setting in _settings_paths.keys():
		ProjectSettings.set_setting(
			_settings_paths[setting]["path"],
			_settings_paths[setting]["default"]
		)
	ProjectSettings.save()

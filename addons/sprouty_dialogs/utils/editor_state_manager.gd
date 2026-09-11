@tool
class_name SproutyDialogsEditorStateManager
extends RefCounted

# -----------------------------------------------------------------------------
# Sprouty Dialogs State Editor Manager
# -----------------------------------------------------------------------------
## This class manages the temporary editor parameters for the Sprouty Dialogs plugin.
## It provides methods to get and set editor default values.
# -----------------------------------------------------------------------------

## Path in which the cache file that stores editor state will be saved.
const EDITOR_STATE_FILE_PATH := "res//.godot/sprouty_dialogs_cache.cfg"

## Temporary editor state parameters.
## This cache file stores settings which should not be versioned.
static var _editor_state_file: ConfigFile:
	get:
		if _editor_state_file:
			return _editor_state_file

		var file := ConfigFile.new()

		if FileAccess.file_exists(EDITOR_STATE_FILE_PATH):
			var load_result := file.load(EDITOR_STATE_FILE_PATH)
			if load_result == OK:
				_editor_state_file = file
				return file
			else:
				printerr("[SproutyDialogs] Couldn't load editor state cache file. An error occurred: "
					+ error_string(load_result))
				return null

		# Set default values
		file.set_value("window_state", "play_dialog_path", "")
		file.set_value("window_state", "play_start_id", "")
		file.set_value("window_state", "last_opened_files", [])
		file.set_value("window_state", "last_selected_file_index", -1)

		file.save(EDITOR_STATE_FILE_PATH)
		_editor_state_file = file
		return file


## Returns an editor state value from the cache file.
## If the value section or key are not found, it returns null and prints an error message.
static func get_value(section: String, key: String) -> Variant:
	if not _editor_state_file.has_section(section):
		printerr("[SproutyDialogs] Editor state section '" + section + "' not found.")
		return null
	if not _editor_state_file.has_section_key(section, key):
		printerr("[SproutyDialogs] Editor state key '" + key + "' not found in section '" + section + "'.")
		return null

	return _editor_state_file.get_value(section, key)


## Sets an editor state value in the cache file.
## If the value section or key are not found, it prints an error message.
static func set_value(section: String, key: String, value: Variant) -> void:
	if not _editor_state_file.has_section(section):
		printerr("[SproutyDialogs] Editor state section '" + section + "' not found."
			+ "Cannot set value of key '" + key + "' for that section.")
		return
	if not _editor_state_file.has_section_key(section, key):
		printerr("[SproutyDialogs] Editor state key '" + key + "' not found in section '" + section
			+ "'. Cannot set value.")
		return

	_editor_state_file.set_value(section, key, value)
	_editor_state_file.save(EDITOR_STATE_FILE_PATH)


## Migrates editor state from project settings to the cache file.
## This function is called when the plugin is first loaded, and it checks if there are any
## editor state values stored in the project settings. If there are, it migrates them to
## the cache file and removes them from the project settings.
static func migrate_editor_state_from_project_settings() -> void:
	var settings := [
		"sprouty_dialogs/internal/play_dialog_path",
		"sprouty_dialogs/internal/play_start_id",
		"sprouty_dialogs/internal/last_opened_files",
		"sprouty_dialogs/internal/last_selected_file_index"
	]
	for setting in settings:
		if ProjectSettings.has_setting(setting):
			var value := ProjectSettings.get_setting(setting)
			var key = setting.split("/")[-1]
			set_value("window_state", key, value)
			ProjectSettings.set_setting(setting, null)
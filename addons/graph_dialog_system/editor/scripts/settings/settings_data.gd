class_name GDialogsSettingsData
extends Resource

## ------------------------------------------------------------------
## Handle plugin settings data
## ------------------------------------------------------------------

const DATA_PATH = "res://addons/graph_dialog_system/editor/data/settings.json"

# --- Translation settings ---
static var translation_settings := {}

static func save_settings():
	# Save settings data on a JSON file
	var dict := {
		"graph_dialogs_settings" : {
			"translation": translation_settings
		}
	}
	GDialogsJSONFileManager.save_file(dict, DATA_PATH)

static func load_settings():
	# Load settings data from a JSON file
	var data = GDialogsJSONFileManager.load_file(DATA_PATH)
	
	translation_settings = data.graph_dialogs_settings.translation

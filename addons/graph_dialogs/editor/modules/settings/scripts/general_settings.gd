@tool
extends Control

## Default dialog box path to load if no dialog box is specified.
const DEFAULT_BOX_PATH = "res://addons/graph_dialogs/objects/defaults/default_dialog_box.tscn"

## Path of the general settings in project settings
var _settings_path: String = "graph_dialogs/general/"


func _ready():
	# If the default dialog box setting is not set, create a default one
	if not ProjectSettings.has_setting("graph_dialogs/general/default_dialog_box"):
		ProjectSettings.set_setting(
			"graph_dialogs/general/default_dialog_box",
			ResourceSaver.get_resource_id_for_path(DEFAULT_BOX_PATH)
		)
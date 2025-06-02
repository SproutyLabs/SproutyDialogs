@tool
class_name GraphDialogsFileUtils
extends Node

## -----------------------------------------------------------------------------
## File Utils
##
## This module is responsible for some file operations and references.
## -----------------------------------------------------------------------------

## Last used paths for file dialogs
static var recent_file_paths: Dictionary = {
	"graph_dialogs_files": "res://",
	"dialogue_files": "res://",
	"character_files": "res://",
	"csv_dialog_files": "res://",
	"text_box_files": "res://",
	"portrait_files": "res://",
}


## Get the last used path for a file in a file dialog
static func get_recent_file_path(file_type: String) -> String:
	if recent_file_paths.has(file_type):
		return recent_file_paths[file_type]
	return "res://"


## Set the last used path for a file in a file dialog
static func set_recent_file_path(file_type: String, path: String) -> void:
	recent_file_paths[file_type] = path.get_base_dir()


## Check if the path has valid extension
static func check_valid_extension(path: String, extensions: Array) -> bool:
	if path.is_empty():
		return false
	for ext in extensions:
		if path.ends_with(ext.replace("*", "")):
			return true
	return false
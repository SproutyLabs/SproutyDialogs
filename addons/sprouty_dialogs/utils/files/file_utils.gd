@tool
class_name SproutyDialogsFileUtils
extends Node

# -----------------------------------------------------------------------------
# Sprouty Dialogs File Utils
# -----------------------------------------------------------------------------
## This module is responsible for some file operations and references.
## It provides methods to manage recent file paths, check file extensions,
## validate resource UIDs, and ensure unique naming within a list.
# -----------------------------------------------------------------------------

## Last used paths for file dialogs
static var recent_file_paths: Dictionary = {
	"graph_dialogs_files": "res://",
	"dialogue_files": "res://",
	"character_files": "res://",
	"csv_dialog_files": "res://",
	"dialog_box_files": "res://",
	"portrait_files": "res://",
}


## Get the last used path for a file type in a file dialog
static func get_recent_file_path(file_type: String) -> String:
	if recent_file_paths.has(file_type):
		return recent_file_paths[file_type]
	return "res://"


## Set the last used path for a file type in a file dialog
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


## Check if a UID has a valid resource path associated with it
static func check_valid_uid_path(uid: int) -> bool:
	return uid != -1 and ResourceUID.has_id(uid) \
			and ResourceLoader.exists(ResourceUID.get_id_path(uid))


## Ensure a name is unique within a list of existing names
static func ensure_unique_name(name: String, existing_names: Array,
		empty_name: String = "Unnamed") -> String:
	if name.strip_edges() == "":
		name = empty_name # Set default name if empty
	
	if not existing_names.has(name):
		return name # Name is already unique

	# Remove existing suffix if any
	var regex = RegEx.new()
	regex.compile("(?: \\(\\d+\\))?$")
	var result = regex.search(name)
	var clean_name = name
	if result:
		clean_name = regex.sub(name, "").strip_edges()
	
	# Append suffix until unique
	var suffix := 1
	var new_name = clean_name + " (" + str(suffix) + ")"
	while existing_names.has(new_name):
		suffix += 1
		new_name = clean_name + " (" + str(suffix) + ")"
	
	return new_name
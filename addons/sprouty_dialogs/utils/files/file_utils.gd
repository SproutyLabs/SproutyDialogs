@tool
class_name SproutyDialogsFileUtils
extends RefCounted

# -----------------------------------------------------------------------------
# Sprouty Dialogs File Utils
# -----------------------------------------------------------------------------
## This module is responsible for some file operations and references.
## It provides methods to manage recent file paths, check file extensions,
## validate resource UIDs, and other useful methods.
# -----------------------------------------------------------------------------

## Last used paths for file dialogs
static var _recent_file_paths: Dictionary = {
	"graph_dialogs_files": "res://",
	"dialogue_files": "res://",
	"character_files": "res://",
	"csv_dialog_files": "res://",
	"dialog_box_files": "res://",
	"portrait_files": "res://",
}


## Get the last used path for a file type in a file dialog
static func get_recent_file_path(file_type: String) -> String:
	if _recent_file_paths.has(file_type):
		return _recent_file_paths[file_type]
	return "res://"


## Set the last used path for a file type in a file dialog
static func set_recent_file_path(file_type: String, path: String) -> void:
	_recent_file_paths[file_type] = path.get_base_dir()


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


## Open a scene in the editor given its path.
## Also, needs a reference to the SceneTree (using Node.get_tree()) to process a timer.
static func open_scene_in_editor(scene_path: String, scene_tree: SceneTree) -> void:
	if check_valid_extension(scene_path, ["*.tscn", "*.scn"]):
		if ResourceLoader.exists(scene_path):
			var editor_interface = Engine.get_singleton("EditorInterface")
			editor_interface.open_scene_from_path(scene_path)
			await scene_tree.process_frame
			editor_interface.set_main_screen_editor("2D")
	else:
		printerr("[Sprouty Dialogs] Invalid scene file path.")


## Create a new dialog box or portrait scene file.
## Needs the path where save the scene file and the type of the scene that can
## be "dialog_box" or "portrait_scene".
static func create_new_scene_file(scene_path: String, scene_type: String) -> void:
	var default_uid = SproutyDialogsSettingsManager.get_setting("default_" + scene_type)
	var default_path = ""
	
	# If no default portrait scene is set or the resource does not exist, use the built-in default
	if not SproutyDialogsFileUtils.check_valid_uid_path(default_uid):
		printerr("[Sprouty Dialogs] No default " + scene_type + " found." \
				+" Check that the default portrait scene is set in Settings > General" \
				+" plugin tab, and that the scene resource exists. Using built-in default instead.")
		match scene_type: # Use and set the setting to the built-in default
			"dialog_box":
				default_path = SproutyDialogsSettingsManager.DEFAULT_DIALOG_BOX_PATH
			"portrait_scene":
				default_path = SproutyDialogsSettingsManager.DEFAULT_PORTRAIT_PATH
		
		SproutyDialogsSettingsManager.set_setting("default_" + scene_type,
				ResourceSaver.get_resource_id_for_path(default_path, true))
	else: # Use the user-defined default portrait scene
		default_path = ResourceUID.get_id_path(default_uid)
	
	var new_scene = load(default_path).instantiate()
	new_scene.name = scene_path.get_file().split(".")[0].to_pascal_case()

	# Creates and set a template script for the new scene
	var script_path := scene_path.get_basename() + ".gd"
	var script = GDScript.new()
	script.source_code = new_scene.get_script().source_code
	ResourceSaver.save(script, script_path)
	new_scene.set_script(load(script_path))

	# Save the new scene file
	var packed_scene = PackedScene.new()
	packed_scene.pack(new_scene)
	ResourceSaver.save(packed_scene, scene_path)
	new_scene.queue_free()

	# Set the recent file path
	set_recent_file_path(scene_type.replace("_scene", "") + "_files", scene_path)
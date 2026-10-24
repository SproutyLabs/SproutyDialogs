@tool
class_name SproutyDialogsFileUtils
extends RefCounted

# -----------------------------------------------------------------------------
# Sprouty Dialogs File Utils
# -----------------------------------------------------------------------------
## This module is responsible for some file operations and references.
## It provides methods to manage recent file paths, check file extensions,
## validate resource UIDs, load resources by UID with a file path fallback,
## and other useful methods.
# -----------------------------------------------------------------------------

## Last used paths for file dialogs
static var _recent_file_paths: Dictionary = {
	"sprouty_files": "res://",
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


## Returns a resource reference dictionary with the given resource UID and file
## path. This is the format used to store the resource references in the plugin
## data (e.g. the character references of the dialogue data), so the resource
## can still be loaded by its path when the UID is no longer valid.
static func make_reference(uid: int = -1, path: String = "") -> Dictionary:
	return {"uid": uid, "path": path}


## Returns a resource reference dictionary for the resource at the given path,
## storing both its UID and the path itself to load the resource as a fallback.
static func build_reference(path: String) -> Dictionary:
	return {"uid": ResourceSaver.get_resource_id_for_path(path, true), "path": path}


## Normalizes a stored resource reference to a dictionary with "uid" and
## "path" keys. Accepts legacy references storing only the resource UID as an
## int, returning a reference with the UID and an empty path. Any other value
## is normalized to an empty reference.
static func normalize_reference(reference: Variant) -> Dictionary:
	if reference is Dictionary:
		return {
			"uid": reference.get("uid", -1),
			"path": str(reference.get("path", "")),
		}
	if reference is int:
		return make_reference(reference)
	return make_reference()


## Check if a resource reference ("uid"/"path" dictionary) is empty, meaning
## that it stores no usable UID nor file path.
static func reference_is_empty(reference: Variant) -> bool:
	if not reference is Dictionary:
		return true
	var reference_normalized = normalize_reference(reference)
	return reference_normalized["uid"] == -1 and reference_normalized["path"].is_empty()


## Returns the file path of a resource UID, using the given path as fallback
## when the UID is no longer valid (e.g. the resource was renamed or moved
## outside of the editor). Returns an empty string when none of them is valid.
static func get_uid_path(uid: int, path_fallback: String = "") -> String:
	if check_valid_uid_path(uid):
		return ResourceUID.get_id_path(uid)
	if not path_fallback.is_empty() and FileAccess.file_exists(path_fallback):
		return path_fallback
	return ""


## Returns the resolved file path of a resource reference ("uid"/"path"
## dictionary). The stored UID is resolved first, using the stored path as
## fallback when the UID is no longer valid. Returns an empty string when the
## path cannot be resolved.
static func reference_path(reference: Variant) -> String:
	if not reference is Dictionary:
		return ""
	return get_uid_path(reference.get("uid", -1), str(reference.get("path", "")))


## Load a resource by its UID, using the given path as fallback.
## The resource is loaded from its UID path first; when the UID is no longer
## valid (e.g. the resource was renamed or moved outside of the editor), the
## resource is loaded from the fallback path instead, if the file exists there.
## Returns null when the resource cannot be loaded.
static func load_resource(uid: int, path_fallback: String = "") -> Resource:
	var path: String = get_uid_path(uid, path_fallback)
	if path.is_empty():
		return null
	return load(path)


## Load a resource from a resource reference ("uid"/"path" dictionary).
## The resource is loaded from its stored UID first, using the stored path
## as fallback when the UID is no longer valid.
## Returns null when the resource cannot be loaded.
static func load_reference(reference: Variant) -> Resource:
	if not reference is Dictionary:
		return null
	return load_resource(reference.get("uid", -1), str(reference.get("path", "")))


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
	var default_reference = SproutyDialogsSettingsManager.get_reference_setting(
			"default_" + scene_type)
	var default_path = reference_path(default_reference)
	
	# If no default portrait scene is set or the resource does not exist, use the built-in default
	if default_path.is_empty():
		printerr("[Sprouty Dialogs] No default " + scene_type + " found." \
				+ " Check that the default portrait scene is set in Settings > General" \
				+ " plugin tab, and that the scene resource exists. Using built-in default instead.")
		match scene_type: # Use and set the setting to the built-in default
			"dialog_box":
				default_path = SproutyDialogsSettingsManager.DEFAULT_DIALOG_BOX_PATH
			"portrait_scene":
				default_path = SproutyDialogsSettingsManager.DEFAULT_PORTRAIT_PATH
		
		SproutyDialogsSettingsManager.set_reference_setting(
				"default_" + scene_type, default_path)
	
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


## Return all the resources of a given type in the project.
## The type can be: "dialogue" or "character" resource.
static func get_resources_of_type(type: String = "dialogue", path: String = "res://") -> Array:
	var dialogue_resources: Array = []
	var dir = DirAccess.open(path)
	
	if not dir:
		printerr("[Sprouty Dialogs] Cannot open directory: " + path)
		return dialogue_resources
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		# Skip hidden files and current/parent directory markers
		if not file_name.begins_with("."):
			var file_path = path.path_join(file_name)
			
			# If it's a directory, recurse
			if dir.current_is_dir():
				var sub_resources = get_resources_of_type(type, file_path)
				dialogue_resources.append_array(sub_resources)
			# If it's a file with .tres extension, try to load it
			elif file_name.ends_with(".tres"):
				var resource = load(file_path)
				match type:
					"dialogue":
						if resource is SproutyDialogsDialogueData:
							dialogue_resources.append(resource)
					"character":
						if resource is SproutyDialogsCharacterData:
							dialogue_resources.append(resource)
		
		file_name = dir.get_next()
	
	return dialogue_resources


## Loads a character resource from a character reference of the dialogue data.
## Legacy references storing only the character UID are also accepted.
## The reference is tried, in this order: by its stored UID, by its stored
## file path, and by searching the project for a character whose current file
## name / key name matches [param character_key].
## Returns the loaded character resource, or null when it is not found.
static func load_character_reference(character_key: String,
		reference: Variant) -> SproutyDialogsCharacterData:
	reference = normalize_reference(reference)
	
	# Load the character by its stored UID, using the stored path as fallback
	# when the UID no longer resolves (e.g. the character file was renamed or
	# moved outside of the editor)
	var char_resource = load_reference(reference)
	
	if char_resource == null:
		# The stored path is not valid either, so search the project for a
		# character whose current file name / key name matches the key
		var found = find_character_resource_by_key(character_key)
		if found:
			char_resource = load(found.resource_path)
	
	if not char_resource is SproutyDialogsCharacterData:
		return null
	return char_resource


## Search for a character resource by its file name or its key name in the
## whole project. Used to recover character references when the character file
## was renamed or moved outside of the plugin editor, so its reference UID is
## no longer valid. Returns the character resource or null if it is not found.
static func find_character_resource_by_key(
		character_key: String, path: String = "res://") -> SproutyDialogsCharacterData:
	var resources = get_resources_of_type("character", path)
	
	# First, prefer the character file named exactly as the reference key
	# (the file name is the current key name of the character), since the
	# key_name stored on its file may not be updated to the new file name yet
	for character in resources:
		if character.resource_path.get_file().get_basename() == character_key:
			return character
	
	# Otherwise, use the character whose current key_name matches the reference
	# key, only when it is unambiguous (there is no more than one match)
	var key_matches: Array = resources.filter(
			func(character) -> bool: return character.key_name == character_key)
	if key_matches.size() == 1:
		return key_matches[0]
	if key_matches.size() > 1:
		push_warning("[Sprouty Dialogs] Several character files match the key name '"
				+ character_key + "'. Update the character references on the dialogue"
				+ " nodes to fix this ambiguity.")
	return null

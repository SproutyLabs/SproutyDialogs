class_name SproutyDialogsResourceManager
extends Node

# -----------------------------------------------------------------------------
# Sprouty Dialogs Resource Manager
# -----------------------------------------------------------------------------
## This class is responsible for managing the resources used in the Sprouty 
## Dialogs plugin when running a dialog.
##
## It loads the character data, dialog boxes and portraits. It also provides 
## methods to instantiate the dialog boxes and portraits during the dialogs.
##
## This manager is only use at runtime as a singleton when a dialog is played.
## You should not access or use this class directly.
# -----------------------------------------------------------------------------	

## Dictionary to store the characters loaded from the dialogue data.
## The keys are character names and the values are the character data resources.
## The dictionary structure is:
## [codeblock]{
##   "character_name_1": SproutyDialogsCharacterData resource,
##   "character_name_2": SproutyDialogsCharacterData resource,
##   ...
## }[/codeblock]
var _characters_data: Dictionary = {}
## Dictionary to store the dialog boxes loaded from the dialogue data.
## The keys are dialog box names and the values are DialogBox scenes loaded.
## The dictionary structure is:
## [codeblock]{
##   "dialog_box_name_1": DialogBox PackedScene resource,
##   "dialog_box_name_2": DialogBox PackedScene resource,
##   ...
## }[/codeblock]
var _dialog_boxes: Dictionary = {}
## Dictionary to store the character portraits loaded from dialogue data.
## The keys are character names and the values are dictionaries with
## portrait names as keys and DialogPortrait scenes loaded as values.
## The dictionary structure is:
## [codeblock]{
##   "character_name_1": {
##     "portrait_name_1": DialogPortrait PackedScene resource,
##     "portrait_name_2": DialogPortrait PackedScene resource,
##     ...
##   },
##   ...
## }[/codeblock]
var _portraits: Dictionary = {}

## Characters count in dialog players.
## Keep track of how many dialog players are using each character.
## The dictionary structure is:
## [codeblock]{
##   "character_name_1": int,
##   "character_name_2": int,
##   ...
## }[/codeblock]
var _characters_count: Dictionary = {}
## Dialog boxes count in dialog players.
## Keep track of how many dialog players are using each dialog box.
## The dictionary structure is:
## [codeblock]{
##   "dialog_box_uid_1": int,
##   "dialog_box_uid_2": int,
##   ...
## }[/codeblock]
var _dialog_boxes_count: Dictionary = {}
## Portraits count in dialog players.
## Keep track of how many dialog players are using each portrait.
## The dictionary structure is:
## [codeblock]{
##   "character_name_1": {
##     "portrait_name_1": int,
##     "portrait_name_2": int,
##     ...
##   },
##   ...
## }[/codeblock]
var _portraits_count: Dictionary = {}

## CanvasLayer to display the dialog box.
var _dialog_boxes_canvas: CanvasLayer = null
## CanvasLayer to display the portraits.
var _portraits_canvas: CanvasLayer = null


func _enter_tree() -> void:
	# Initialize the dialog box and portrait canvases
	_portraits_canvas = _new_canvas_layer(
		"PortraitsCanvas", SproutyDialogsSettingsManager.get_setting("portraits_canvas_layer"))
	_dialog_boxes_canvas = _new_canvas_layer(
		"DialogBoxCanvas", SproutyDialogsSettingsManager.get_setting("dialog_box_canvas_layer"))
	
	# Load the default dialog box
	var default_box_uid = SproutyDialogsSettingsManager.get_setting("default_dialog_box")
	if not SproutyDialogsFileUtils.check_valid_uid_path(default_box_uid):
		printerr("[Sprouty Dialogs] No default dialog box scene found." \
				+" Check that the default dialog box is set in Settings > General" \
				+" plugin tab, and that the scene resource exists.")
		return
	var default_box_path = ResourceUID.get_id_path(default_box_uid)
	_dialog_boxes[default_box_path] = load(default_box_path)


## Returns character data for a given character key name
## If the character is not loaded, returns null.
func get_character_data(key_name: String) -> SproutyDialogsCharacterData:
	if _characters_data.has(key_name):
		return _characters_data[key_name]
	return null


## Releases the resources used by a dialog player.
## This will remove the character data, dialog boxes, and portraits
## that are no longer needed by any dialog player.
func release_resources(dialog_data: SproutyDialogsDialogueData, start_id: String) -> void:
	if not dialog_data: return
	var portraits = dialog_data.get_portraits_on_dialog(start_id)

	if not dialog_data.characters.has(start_id):
		return # # If no characters data, Nothing to release

	for char in dialog_data.characters[start_id]:
		# Remove the dialog boxes loaded if they are not used anymore
		if _characters_data.has(char):
			var dialog_box_uid = _characters_data[char].dialog_box_uid
			var dialog_box_path = ""
			if SproutyDialogsFileUtils.check_valid_uid_path(dialog_box_uid):
				dialog_box_path = ResourceUID.get_id_path(dialog_box_uid)
			if _dialog_boxes_count.has(dialog_box_path):
				_dialog_boxes_count[dialog_box_path] -= 1
				# If the dialog box is not used anymore
				if _dialog_boxes_count[dialog_box_path] <= 0:
					if _dialog_boxes.has(dialog_box_path):
						_dialog_boxes.erase(dialog_box_path)
					_dialog_boxes_count.erase(dialog_box_path)
		
		# Remove the portraits loaded if they are not used anymore
		if portraits.has(char) and _portraits_count.has(char):
			for portrait_name in portraits[char]:
				if _portraits_count[char].has(portrait_name):
					_portraits_count[char][portrait_name] -= 1
					# If the portrait is not used anymore
					if _portraits_count[char][portrait_name] <= 0:
						if _portraits.has(char) and _portraits[char].has(portrait_name):
							_portraits[char].erase(portrait_name)
						_portraits_count[char].erase(portrait_name)
		
		# Remove the character from all references if it is not used anymore
		if _characters_count.has(char):
			_characters_count[char] -= 1
			if _characters_count[char] <= 0:
				_characters_data.erase(char)
				_characters_count.erase(char)
				_portraits.erase(char)
				_portraits_count.erase(char)


## Creates a new CanvasLayer with the given name and layer.
func _new_canvas_layer(name: String, layer: int) -> CanvasLayer:
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = name
	canvas_layer.layer = layer
	add_child(canvas_layer)
	return canvas_layer


#region === Load Resources =====================================================

## Load the resources needed to run a dialog.
## This will load the character data, dialog boxes, and portraits for the dialog.
## This only loads the resources to use them later, it does not instantiate them.
func load_resources(dialog_data: SproutyDialogsDialogueData, start_id: String) -> void:
	if not dialog_data: return
	var portraits = dialog_data.get_portraits_on_dialog(start_id)

	if not dialog_data.characters.has(start_id):
		return # If no characters data, nothing to load

	for char in dialog_data.characters[start_id]:
		# Load the character data resource if not already loaded
		if not _characters_data.has(char):
			var char_uid = dialog_data.characters[start_id][char]
			if not SproutyDialogsFileUtils.check_valid_uid_path(char_uid):
				printerr("[Sprouty Dialogs] No character resource found for '" + char \
						+"' character in dialog: " + dialog_data.resource_path + \
						". Check that the '" + char + ".tres' character file exists"
						+" or reassign the character in the dialogue nodes.")
				return
			else: # Load the character data resource
				_characters_data[char] = load(ResourceUID.get_id_path(char_uid))
				_characters_count[char] = 1
		else:
			_characters_count[char] += 1
		
		# Load the dialog box for the character if not already loaded
		var dialog_box_uid = _characters_data[char].dialog_box_uid
		if not SproutyDialogsFileUtils.check_valid_uid_path(dialog_box_uid):
			if dialog_box_uid != -1:
				printerr("[Sprouty Dialogs] No dialog box found for '" + char \
						+"' character in dialog: " + dialog_data.resource_path + \
						". Check that the file '" + _characters_data[char].dialog_box_path \
						+"' exists. Using default dialog box instead.")
			# Use the default dialog box if no dialog box is set for the character
			dialog_box_uid = SproutyDialogsSettingsManager.get_setting("default_dialog_box")
			if not SproutyDialogsFileUtils.check_valid_uid_path(dialog_box_uid):
				printerr("[Sprouty Dialogs] No default dialog box scene found." \
						+" Check that the default dialog box is set in Settings > General" \
						+" plugin tab, and that the scene resource exists.")
				return
		
		# Load the dialog box if not already loaded
		var dialog_box_path = ResourceUID.get_id_path(dialog_box_uid)
		if not _dialog_boxes.has(dialog_box_path) or not _dialog_boxes_count.has(dialog_box_path):
			_dialog_boxes[dialog_box_path] = load(dialog_box_path)
			_dialog_boxes_count[dialog_box_path] = 1
		else:
			_dialog_boxes_count[dialog_box_path] += 1

		if portraits.has(char): # Load the portraits for the character if any
			portraits[char].append(_characters_data[char].default_portrait)
			_load_portraits(char, portraits[char])


## Load the portraits for a character to use them later.
func _load_portraits(character_name: String, portrait_names: Array) -> void:
	if not _portraits.has(character_name):
		_portraits[character_name] = {}
	if not _portraits_count.has(character_name):
			_portraits_count[character_name] = {}
	
	for portrait_name in portrait_names:
		if portrait_name != "" and not _portraits[character_name].has(portrait_name):
			# Get the portrait data from the character resource
			var portrait_data = _characters_data[character_name].get_portrait_from_path_name(portrait_name)
			if not portrait_data:
				printerr("[Sprouty Dialogs] No portrait data found for '" + portrait_name \
						+"' in character '" + character_name + "'. Check that the portrait is" \
						+" in the character resource.")
				_portraits[character_name][portrait_name] = null
				continue
			# If the portrait UID is set, load the portrait scene
			if not SproutyDialogsFileUtils.check_valid_uid_path(portrait_data.portrait_scene_uid):
				printerr("[Sprouty Dialogs] No portrait scene found for '" + portrait_name \
						+"' in character '" + character_name + "'. Check that the file '" \
						+ portrait_data.portrait_scene_path + "' exists.")
				_portraits[character_name][portrait_name] = null
				continue
			else: # Load the portrait scene
				var portrait_scene = load(ResourceUID.get_id_path(portrait_data.portrait_scene_uid))
				_portraits[character_name][portrait_name] = portrait_scene
		
		if not _portraits_count[character_name].has(portrait_name):
			_portraits_count[character_name][portrait_name] = 1
		else:
			_portraits_count[character_name][portrait_name] += 1

#endregion

#region === Instantiate Resources ==============================================

## Instantiate a dialog box for a character in the scene.
## Instantiate from the loaded dialog boxes for the dialogs in the current scene.
## Cannot instantiate a dialog box that was not previously loaded.
func instantiate_dialog_box(character_name: String, dialog_box_parent: Node) -> DialogBox:
	var dialog_box_uid = ""
	if not character_name.is_empty():
		dialog_box_uid = _characters_data[character_name].dialog_box_uid
	
	# If no character or the character has no dialog box, use the default dialog box
	if character_name.is_empty() or not SproutyDialogsFileUtils.check_valid_uid_path(dialog_box_uid):
		dialog_box_uid = SproutyDialogsSettingsManager.get_setting("default_dialog_box")

	var dialog_box_path = ResourceUID.get_id_path(dialog_box_uid)
	
	if not _dialog_boxes.has(dialog_box_path):
		printerr("[Sprouty Dialogs] Cannot instantiate dialog box. No dialog box" \
				+" scene is loaded for the character " + character_name \
				+". Check if the character is in a dialog of the current scene.")
		return null
	var dialog_box = _dialog_boxes[dialog_box_path].instantiate()

	if dialog_box_parent: # Add the dialog box to the specified parent
			dialog_box_parent.add_child(dialog_box)
	else: # If not, add the dialog box to the default canvas
		_dialog_boxes_canvas.add_child(dialog_box)

	return dialog_box


## Instantiate a character portrait.
## Instantiate from the loaded portraits for the dialogs in the current scene.
## Cannot instantiate a portrait that was not previously loaded.
func instantiate_portrait(character_name: String, portrait_name: String,
		portrait_parent: Node, dialog_box: DialogBox = null) -> DialogPortrait:
	if character_name.is_empty() or portrait_name.is_empty():
		return null # If no character or portrait name is provided, return null
	
	if (not _portraits.has(character_name)) or (not _portraits[character_name].has(portrait_name)):
		printerr("[Sprouty Dialogs] Cannot instantiate '" + portrait_name + "' portrait" \
				+" from character '" + character_name + "'. Portrait scene is not loaded." \
				+" The character or portrait are not in a dialog of the current scene.")
		return null
	
	if not _portraits[character_name][portrait_name]:
		print(portrait_name)
		printerr("[Sprouty Dialogs] Cannot instantiate '" + portrait_name + "' portrait" \
				+" from character '" + character_name + "'. No scene is set for '" + portrait_name \
				+"' portrait. Check that the file '" + _characters_data[character_name] \
				.get_portrait_from_path_name(portrait_name).portrait_scene_path \
				+"' exists or reassign the portrait scene in the character resource.")
		return null
	
	var portrait_scene = _portraits[character_name][portrait_name].instantiate()
	_set_portrait_properties(character_name, portrait_name, portrait_scene)
	portrait_scene.name = portrait_name
	
	# If there is a override parent for the portrait, add it to the parent
	if portrait_parent != null:
		var char_parent = _new_portrait_parent(character_name, portrait_parent)
		if not portrait_parent.has_node(NodePath(character_name)):
			portrait_parent.add_child(char_parent)
		char_parent.add_child(portrait_scene)
	# If the portrait is set to be displayed on the dialog box, display it there
	elif _characters_data[character_name].portrait_on_dialog_box and dialog_box:
		var char_parent = _new_portrait_parent(character_name, dialog_box)
		dialog_box.display_portrait(char_parent, portrait_scene)
	else: # If no parent is set, add it to the default canvas
		var char_parent = _new_portrait_parent(character_name, _portraits_canvas)
		if not _portraits_canvas.has_node(NodePath(char_parent.name)):
			_portraits_canvas.add_child(char_parent)
		char_parent.add_child(portrait_scene)

	return portrait_scene


## Set the export overrides and transform settings for a portrait scene.
func _set_portrait_properties(character_name: String,
		portrait_name: String, portrait_scene: DialogPortrait) -> void:
	if not _characters_data.has(character_name):
		printerr("[Sprouty Dialogs] No character data found for '" + character_name + "'." \
				+" Cannot set portrait properties.")
		return
	
	var portrait_data = _characters_data[character_name].get_portrait_from_path_name(portrait_name)
	if not portrait_data:
		printerr("[Sprouty Dialogs] No portrait data found for '" + portrait_name \
				+"' in character " + character_name + ". Cannot set portrait properties.")
		return
	
	for prop in portrait_data.export_overrides: # Set export overrides
		var value = portrait_data.export_overrides[prop]["value"]
		var type = portrait_data.export_overrides[prop]["type"]
		# If the property is a collection, get the real value
		if type == TYPE_DICTIONARY:
			value = _get_dictionary_from_data(value)
		elif type == TYPE_ARRAY:
			value = _get_array_from_data(value)
		portrait_scene.set(prop, value)
	
	# Set transform settings
	var main_transform = _characters_data[character_name].main_transform_settings
	var transform_settings = portrait_data.transform_settings

	# Add the parent transform
	if not transform_settings.ignore_main_transform:
		transform_settings.scale += main_transform.scale
		transform_settings.offset += main_transform.offset
		transform_settings.rotation += main_transform.rotation
		transform_settings.mirror = not main_transform.mirror \
				if transform_settings.mirror else main_transform.mirror
	
	# Set transform settings in portrait scene
	portrait_scene.scale = transform_settings.scale
	portrait_scene.position = transform_settings.offset
	portrait_scene.rotation_degrees = transform_settings.rotation
	if transform_settings.mirror:
		portrait_scene.scale.x *= -1


# Create a new parent for the portrait if it doesn't exist
func _new_portrait_parent(character_name: String, parent: Node) -> Control:
	if not parent.get_node_or_null(character_name):
		var node = Control.new()
		node.name = character_name
		node.set_anchors_preset(Control.PRESET_CENTER)
		return node
	return parent.get_node(character_name)


## Recursively get array from array data
func _get_array_from_data(array_data: Array) -> Array:
	var array = []
	for item in array_data:
		var value = item["value"]
		var type = item["type"]
		if type == TYPE_DICTIONARY:
			value = _get_dictionary_from_data(value)
		elif type == TYPE_ARRAY:
			value = _get_array_from_data(value)
		array.append(value)
	return array


## Recursively get dictionary from dictionary data
func _get_dictionary_from_data(dict_data: Dictionary) -> Dictionary:
	var dict = {}
	for key in dict_data.keys():
		var item = dict_data[key]
		var value = item["value"]
		var type = item["type"]
		if type == TYPE_DICTIONARY:
			value = _get_dictionary_from_data(value)
		elif type == TYPE_ARRAY:
			value = _get_array_from_data(value)
		dict[key] = value
	return dict


#endregion

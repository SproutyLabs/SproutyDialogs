class_name GraphDialogsManager
extends Node

## -----------------------------------------------------------------------------
## Graph Dialogs Manager
##
## This is an autoload singleton that manages the Graph Dialogs plugin.
## It handles the loading of character data and dialogue data,
## and provides methods to access the character and dialogue resources.
## -----------------------------------------------------------------------------

## The current dialog data being processed.
var current_dialog_data: GraphDialogsDialogueData = null
## The current dialog ID being processed.
var current_dialog_id: String = ""
## The current dialog node being processed.
var current_dialog_node: String = ""

## CanvasLayer to display the dialog box.
var dialog_boxes_canvas: CanvasLayer = null
## CanvasLayer to display the portraits.
var _portraits_canvas: CanvasLayer = null

## Dictionary to store the characters loaded from the dialog data.
## The keys are character names and the values are the character data resources.
## The dictionary structure is:
## [codeblock]{
##   "character_name_1": GraphDialogsCharacterData resource,
##   "character_name_2": GraphDialogsCharacterData resource,
##   ...
## }[/codeblock]
var _characters: Dictionary = {}
## Dictionary to store the dialog boxes loaded from the dialog data.
## The keys are character names and the values are dictionaries with
## with start IDs as keys and DialogBox instances as values.
## This allows multiple boxes per character, with different parents for each dialog.
## The dictionary structure is:
## [codeblock]{
##   "character_name_1": {
##     "start_id_1": DialogBox instance reference,
##     "start_id_2": DialogBox instance reference,
##     ...
##   },
##   ...
## }[/codeblock]
var _dialog_boxes: Dictionary = {}
## Dictionary to store the character portraits loaded from dialog data.
## The keys are character names and the values are dictionaries with
## portrait names as keys and DialogPortrait scenes loaded as values.
## The dictionary structure is:
## [codeblock]{
##   "character_name_1": {
##     "portrait_name_1": PackedScene resource,
##     "portrait_name_2": PackedScene resource,
##     ...
##   },
##   ...
## }[/codeblock]
var _portraits: Dictionary = {}


func _ready():
	# Initialize the dialog box and portrait canvases
	dialog_boxes_canvas = _new_canvas_layer("DialogBoxCanvas", 2)
	_portraits_canvas = _new_canvas_layer("PortraitCanvas", 1)
	
	# Load the default dialog box
	var default_box_uid = ProjectSettings.get_setting("graph_dialogs/general/default_dialog_box")
	var default_box = load(ResourceUID.get_id_path(default_box_uid)).instantiate()
	default_box.name = "DefaultDialogBox"
	dialog_boxes_canvas.add_child(default_box)


#region === Handle resources ===================================================

## Returns the dialog box for a given character in a specific dialog.
## Only can return a dialog box that is in a dialog of the current scene.
## If the character has no dialog box set, it returns the default dialog box.
func get_dialog_box(start_id: String, character_name: String) -> DialogBox:
	if character_name == "":
		return dialog_boxes_canvas.get_node("DefaultDialogBox")
	
	if (not _dialog_boxes.has(character_name)) or (not _dialog_boxes[character_name].has(start_id)):
		printerr("[GraphDialogs] No dialog box found for character '" + character_name \
				 +"'. Dialog '" + start_id + "' is not in the current scene.")
		return null
	
	return _dialog_boxes[character_name][start_id]


## Instantiate a character portrait in the scene.
## This will load a portrait scene and instantiate it to be used in the dialog.
func instantiate_portrait(start_id: String, character_name: String,
		portrait_name: String, portrait_parent: Node = null) -> DialogPortrait:
	if character_name.is_empty() or portrait_name.is_empty():
		return null
	if (not _portraits.has(character_name)) or (not _portraits[character_name].has(portrait_name)):
		printerr("[GraphDialogs] No '" + portrait_name + " portrait scene found " \
				+"' from character " + character_name \
				+". The character or portrait are not in a dialog of the current scene.")
		return null
	var portrait_scene = _portraits[character_name][portrait_name].instantiate()
	portrait_scene.name = character_name + "_" + portrait_name

	# If the portrait is set to be displayed on the dialog box, display it there
	if _characters[character_name].portrait_on_dialog_box:
		get_dialog_box(start_id, character_name).display_portrait(portrait_scene)
	# If there is a parent for the portrait, add it to the parent
	elif portrait_parent:
		portrait_parent.add_child(portrait_scene)
	else: # If no parent is set, add it to the default canvas
		_portraits_canvas.add_child(portrait_scene)
	return portrait_scene


## Load the resources needed for run a dialog from the dialog data.
## This includes characters, dialog boxes, and portraits.
func load_resources(dialog_data: GraphDialogsDialogueData,
		start_id: String, dialog_box_parents: Dictionary) -> void:
	if not dialog_data: return
	var portraits = dialog_data.get_portraits_on_dialog(start_id)

	for char in dialog_data.characters[start_id]:
		# Store the character data if not already loaded
		if not _characters.has(char):
			_characters[char] = load(
					ResourceUID.get_id_path(dialog_data.characters[start_id][char])
				)
		_load_dialog_box(start_id, char, dialog_box_parents)
		_load_portraits(char, portraits[char])
	
	print("\n- Dialog boxes:")
	print(_dialog_boxes)
	print("\n- Portraits:")
	print(_portraits)


## Load and instantiate the dialog box for a character.
func _load_dialog_box(start_id: String, character_name: String, dialog_box_parents: Dictionary) -> void:
	# Add the character to the dialog boxes dictionary if not already present
	if not _dialog_boxes.has(character_name):
			_dialog_boxes[character_name] = {}

	# If the character has a dialog box set, load it
	if _characters[character_name].dialog_box:
		var dialog_box = load(ResourceUID.get_id_path(
				_characters[character_name].dialog_box)).instantiate()
		dialog_box.name = character_name + "_DialogBox"

		# If a dialog box parent is set, add the dialog box to it
		if dialog_box_parents.has(character_name) and dialog_box_parents[character_name] != null:
				dialog_box_parents[character_name].add_child(dialog_box)
		else: # If not, add the dialog box to the default canvas
			dialog_boxes_canvas.add_child(dialog_box)
		
		_dialog_boxes[character_name][start_id] = dialog_box
	else: # If no dialog box is set, use the default one
		_dialog_boxes[character_name][start_id] = dialog_boxes_canvas.get_node("DefaultDialogBox")


## Load the portraits for a character to use them later.
func _load_portraits(character_name: String, portrait_names: Array) -> void:
	# If the character is not in the portraits dictionary, add it
	if not _portraits.has(character_name):
		_portraits[character_name] = {}
	
	for portrait_name in portrait_names:
		if not _portraits[character_name].has(portrait_name):
			# Get the portrait data from the character resource
			var portrait_data = _characters[character_name].get_portrait_from_path_name(portrait_name)
			if not portrait_data:
				printerr("[GraphDialogs] No portrait data found for '" + portrait_name \
						+"' in character " + character_name)
				continue
			# If the portrait UID is set, load the portrait scene
			if portrait_data.portrait_scene:
				var portrait_scene = load(ResourceUID.get_id_path(portrait_data.portrait_scene))
				if portrait_scene:
					_portraits[character_name][portrait_name] = portrait_scene
				else:
					printerr("[GraphDialogs] Failed to load '" + portrait_name \
							+"' portrait scene for character " + character_name)
			else: # If no portrait UID is set, there is no portrait scene
				_portraits[character_name][portrait_name] = null


## Creates a new CanvasLayer with the given name and layer.
func _new_canvas_layer(name: String, layer: int) -> CanvasLayer:
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = name
	canvas_layer.layer = layer
	add_child(canvas_layer)
	return canvas_layer

#endregion

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

## Dictionary to store the characters loaded from the dialog data.
## The keys are character names and the values are the character data resources.
## The dictionary structure is:
## [codeblock]{
##   "character_name": GraphDialogsCharacterData reference,
##   "character_name_2": GraphDialogsCharacterData reference,
##   ...
## }[/codeblock]
var _characters_in_scene: Dictionary = {}
## Dictionary to store the dialog boxes loaded from the dialog data.
## The keys are character names and the values are dictionaries with
## with start IDs as keys and dialog box instances as values.
## This allows multiple boxes per character, with different parents for each dialog.
## The dictionary structure is:
## [codeblock]{
##   "character_name": {
##     "start_id_1": DialogBox reference,
##     "start_id_2": DialogBox reference,
##     ...
##   },
##   ...
## }[/codeblock]
var _dialog_boxes: Dictionary = {}

## CanvasLayer to display the dialog box.
var _dialog_box_canvas: CanvasLayer = null
## CanvasLayer to display the portraits.
var _portrait_canvas: CanvasLayer = null


func _ready():
	# Initialize the dialog box and portrait canvases
	_dialog_box_canvas = _new_canvas_layer("DialogBoxCanvas", 2)
	_portrait_canvas = _new_canvas_layer("PortraitCanvas", 1)
	
	# Load the default dialog box
	var default_box_uid = ProjectSettings.get_setting("graph_dialogs/general/default_dialog_box")
	var default_box = load(ResourceUID.get_id_path(default_box_uid)).instantiate()
	default_box.name = "DefaultDialogBox"
	_dialog_box_canvas.add_child(default_box)


#region === Handle resources ===================================================

# Returns the character data resource for the given character name.
func get_character(character_name: String) -> GraphDialogsCharacterData:
	if _characters_in_scene.has(character_name):
		return _characters_in_scene[character_name]
	else:
		printerr("[Graph Dialogs] Character not found: " + character_name)
		return null


## Returns the dialog box for a given character in a specific dialog.
func get_dialog_box(start_id: String, character_name: String) -> DialogBox:
	if character_name == "":
		return _dialog_box_canvas.get_node("DefaultDialogBox")
	return _dialog_boxes[character_name][start_id]


# Load the resources needed for run the dialog.
# This includes characters, dialog boxes, and portraits.
func load_resources(dialog_data: GraphDialogsDialogueData, start_id: String,
		portrait_parents: Dictionary, dialog_box_parents: Dictionary) -> void:
	if not dialog_data: return
	for char in dialog_data.characters[start_id]:
		# Store the character data if not already loaded
		if not _characters_in_scene.has(char):
			_characters_in_scene[char] = load(
					ResourceUID.get_id_path(dialog_data.characters[start_id][char])
				)
		_load_dialog_box(start_id, char, dialog_box_parents)
		#_load_portraits(_dialog_box_canvas.get_node(char + "_DialogBox"), start_id)


## Load the dialog box for the character in the scene.
func _load_dialog_box(start_id: String, character_name: String, dialog_box_parents: Dictionary) -> void:
	# Add the character to the dialog boxes dictionary if not already present
	if not _dialog_boxes.has(character_name):
			_dialog_boxes[character_name] = {}

	# If the character has a dialog box set, load it
	if _characters_in_scene[character_name].dialog_box:
		var dialog_box = load(ResourceUID.get_id_path(
				_characters_in_scene[character_name].dialog_box)).instantiate()
		dialog_box.name = character_name + "_DialogBox"

		# If a dialog box parent is set, add the dialog box to it
		if dialog_box_parents.has(character_name) and dialog_box_parents[character_name] != null:
				dialog_box_parents[character_name].add_child(dialog_box)
		else: # If not, add the dialog box to the default canvas
			_dialog_box_canvas.add_child(dialog_box)
		
		_dialog_boxes[character_name][start_id] = dialog_box
	else: # If no dialog box is set, use the default one
		_dialog_boxes[character_name][start_id] = _dialog_box_canvas.get_node("DefaultDialogBox")


## Load the portraits for the character in the scene.
func _load_portraits(char_node: Node, start_id: String):
		var portraits = _characters_in_scene[char_node.name].get_portraits_on_dialog(start_id)
		var portrait_node = null

		# Check if the portraits node already exists or create it
		if not char_node.find_child("Portraits"):
			portrait_node = Node.new()
			portrait_node.name = "Portraits"
			char_node.add_child(portrait_node)
		else:
			portrait_node = char_node.get_node("Portraits")

		for portrait in portraits:
			if portrait_node.has_node(portrait):
				continue # Skip if the portrait already exists
			
			var portrait_data = _characters_in_scene[char_node.name].portraits[portrait]
			var portrait_scene = load(ResourceUID.get_id_path(portrait_data.portrait_scene))
			if not portrait_scene:
				printerr("[Graph Dialogs] Cannot load portrait scene: " + \
					ResourceUID.get_id_path(portrait_data.portrait_scene))
				return null
			
			var portrait_instance = portrait_scene.instantiate()
			portrait_instance.update_portrait()
			portrait_instance.name = portrait
			portrait_node.add_child(portrait_instance)


## Creates a new CanvasLayer with the given name and layer.
func _new_canvas_layer(name: String, layer: int) -> CanvasLayer:
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = name
	canvas_layer.layer = layer
	add_child(canvas_layer)
	return canvas_layer

#endregion

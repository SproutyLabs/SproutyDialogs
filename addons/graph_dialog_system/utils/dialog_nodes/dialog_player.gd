@tool
@icon("res://addons/graph_dialog_system/icons/icon.svg")
class_name DialogPlayer
extends Node

## -----------------------------------------------------------------------------
## Dialog Player to play dialogues from a JSON Dialog file.
##
## It reads the dialog file and processes the dialog tree to play the dialogues.
## The dialog tree is composed of nodes that represent dialogues and actions.
## The player processes the nodes and plays the dialogues in the dialog boxes.
## -----------------------------------------------------------------------------

## Signal emitted when the dialog is started.
signal dialog_started(id: String)
## Signal emitted when the dialog is ended.
signal dialog_ended

## Play the dialog when the node is ready.
@export var play_on_ready: bool

## JSON Dialog file where is the dialog to play.
@export_file("*.json") var dialog_file: String:
	set(value):
		dialog_file = value
		_load_dialog_data(value)
		_get_starts_ids()
		notify_property_list_changed()

## Start ID of the dialog to play.
var start_id: String:
	set(value):
		start_id = value
		_get_dialog_characters(start_id)
		_dialog_boxes = _create_characters_dict()
		_portrait_displays = _create_characters_dict()
		notify_property_list_changed()

## Dictionary to store the portrait display nodes by character.
var _portrait_displays: Dictionary
## Dictionary to store the dialog box nodes by character.
var _dialog_boxes: Dictionary

## Dictionary to store the dialog nodes data.
var _nodes_data: Dictionary
## Array to store the start IDs of the dialogues.
var _starts_ids: Array[String]
## Array to store the characters keys in dialog to play.
var _chars_keys: Array[String]

## Current dialog box to display the dialog.
var _current_dialog_box: DialogTextBox
## Next node to process in the dialog tree after a dialogue node.
var _next_node: String = ""

## Flag to control if the dialog is running.
var _is_running: bool = false

func _ready() -> void:
	# Connect process node method on each node parser
	for node in NodesReferences.nodes:
		if NodesReferences.nodes[node].parser != null:
			NodesReferences.nodes[node].parser.connect(
				"continue_to_node", _process_node
			)
	# Connect dialogue process method on each dialogue node parser
	NodesReferences.nodes.dialogue_node.parser.connect(
		"dialogue_processed", _on_dialogue_processed
	)
	if not Engine.is_editor_hint():
		# If is running in game mode, load dialog data
		_load_dialog_data(dialog_file)
		if play_on_ready:
			await get_tree().create_timer(0.1).timeout
			start(start_id)

#region === Editor properties ==================================================

func _get_property_list():
	# Set new properties on editor
	if Engine.is_editor_hint():
		var props = []
		# Set available dialogs IDs to select
		if not dialog_file.is_empty():
			var id_list = ""
			for id in _starts_ids:
				id_list += id
				if id != _starts_ids[-1]:
					id_list += ","
			props.append({
				"name": &"start_id",
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": id_list
			})
			# Set characters options by dialog
			if not start_id.is_empty():
				props.append({
				"name": "Characters Settings",
				"type": TYPE_STRING,
				"usage": PROPERTY_USAGE_GROUP,
				"hint_string": "char_",
				})
				for char in _chars_keys:
					props.append({ # Set a group by character name
						"name": char,
						"type": TYPE_STRING,
						"usage": PROPERTY_USAGE_SUBGROUP,
						"hint_string": char,
					})
					props.append({ # Set portrait display node path by character
						"name": char + "_portrait_display",
						"type": TYPE_NODE_PATH,
						"hint": PROPERTY_HINT_NODE_PATH_VALID_TYPES,
						"hint_string": "TextureRect,Sprite2D",
					})
					props.append({ # Set dialogue box node path by character
						"name": char + "_dialogue_box",
						"type": TYPE_NODE_PATH,
						"hint": PROPERTY_HINT_NODE_PATH_VALID_TYPES,
						"hint_string": "DialogBox",
					})
		return props


func _get(property: StringName):
	# Show the portrait display node path by character
	if property.ends_with("_portrait_display"):
		var char_name = property.get_slice("_portrait_", 0)
		return _portrait_displays[char_name]

	# Show the dialogue box node path by character
	if property.ends_with("_dialogue_box"):
		var char_name = property.get_slice("_dialogue_", 0)
		return _dialog_boxes[char_name]


func _set(property: StringName, value: Variant) -> bool:
	# Storing the portrait display node path by character
	if property.ends_with("_portrait_display"):
		var char_name = property.get_slice("_portrait_", 0)
		_portrait_displays[char_name] = value
		return true
	
	# Storing the dialogue box node path by character
	if property.ends_with("_dialogue_box"):
		var char_name = property.get_slice("_dialogue_", 0)
		_dialog_boxes[char_name] = value
		return true
	return false


## Get the start IDs of the dialogues
func _get_starts_ids() -> void:
	_starts_ids = []
	for dialog in _nodes_data:
		if dialog == "unplugged_nodes": continue
		_starts_ids.append(dialog.replace("DIALOG_", ""))


## Get the characters in the dialog tree
func _get_dialog_characters(dialog_id: String) -> Array:
	_chars_keys = []
	var dialog = "DIALOG_" + dialog_id
	for node in _nodes_data[dialog]:
		if _nodes_data[dialog][node]["node_type"] == "dialogue_node":
			if not _chars_keys.has(_nodes_data[dialog][node]["char_key"]):
				_chars_keys.append(_nodes_data[dialog][node]["char_key"])
	return _chars_keys


## Create a dictionary with the characters in the selected dialog
func _create_characters_dict() -> Dictionary:
	var dict = {}
	for char in _chars_keys:
		dict[char] = {}
	return dict
#endregion

## Start processing a dialog tree by ID
func start(id: String = start_id) -> void:
	# Check if the dialog with given id exists
	if not _starts_ids.has(id):
		printerr("[DialogPlayer] Cannot find '" + id + "' ID on dialog file.")
		return
	
	_is_running = true
	var dialog = "DIALOG_" + id

	# Search for start node
	for node in _nodes_data[dialog]:
		 # Start processing from start node
		if node.contains("start_node"):
			_process_node(_nodes_data[dialog][node]["to_node"][0])
			dialog_started.emit(id)
			break


## Stop processing the dialog tree
func stop() -> void:
	_is_running = false
	dialog_ended.emit()


## Check if the dialog is running
func is_running() -> bool:
	return _is_running


## Load dialog data from dialog file
func _load_dialog_data(path: String) -> void:
	# Check if dialog file exists
	if path.is_empty(): return
	if not FileAccess.file_exists(path):
		printerr("[DialogPlayer] Dialog file '" + path + "' does not exist.")
		dialog_file = ""
		return
	
	var data = GDialogsJSONFileManager.load_file(path)
	# If JSON does not contains dialog data
	if not data.has("dialog_data"):
		printerr("[DialogPlayer] Dialog file " + path + "has an invalid format.")
		dialog_file = ""
		return
	# Load dialog nodes data
	_nodes_data = data["dialog_data"]["nodes_data"]


## Process the next node on dialog tree
func _process_node(node_name: String) -> void:
	# Check if the dialog is running
	if not _is_running: return
	# Check if the node is the end node
	if node_name == 'END':
		stop()
		return
	# Get the node type to process
	var node_type = node_name.split("node")[0] + "node"
	NodesReferences.nodes[node_type].parser.process_node(
		_nodes_data["DIALOG_" + start_id][node_name]
		)


## Play the dialog when the dialogue node is processed
func _on_dialogue_processed(char: String, dialog: String, next_node: String) -> void:
	_next_node = next_node
	var dialog_box = get_node(_dialog_boxes[char])
	
	# Check if the dialog box is already playing a dialog
	if _current_dialog_box and dialog_box != _current_dialog_box:
		_current_dialog_box.end_dialog() # End the current dialog
	
	_current_dialog_box = dialog_box

	# Connect the dialog box signals
	if not _current_dialog_box.is_connected("continue_dialog", _on_continue_dialog):
		_current_dialog_box.connect("continue_dialog", _on_continue_dialog)
	
	_current_dialog_box.play_dialog(char, dialog, self)


## Continue to the next node in the dialog tree
func _on_continue_dialog() -> void:
	_process_node(_next_node)

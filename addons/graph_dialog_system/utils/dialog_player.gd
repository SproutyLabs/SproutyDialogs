@tool
@icon("res://addons/graph_dialog_system/icons/icon.svg")
class_name DialogPlayer
extends Node

## ------------------------------------------------------------------
## Class to run a dialog tree
## ------------------------------------------------------------------

signal dialog_started(id: String)
signal dialog_ended

## Play the dialog when the node is ready.
@export var play_on_ready: bool

## JSON Dialog file where is the dialog to play.
@export_file("*.json") var dialog_file: String:
	set(value):
		dialog_file = value
		_load_dialog_data(value)
		_get_dialogs_ids()
		notify_property_list_changed()

## Start ID of the dialog to play.
var start_id: String:
	set(value):
		start_id = value
		_get_dialog_characters(start_id)
		_dialogue_boxes = _create_characters_dict()
		_portrait_displays = _create_characters_dict()
		notify_property_list_changed()

var _portrait_displays: Dictionary
var _dialogue_boxes: Dictionary

var _nodes_data: Dictionary
var _dialogs_ids: Array[String]
var _chars_keys: Array[String]

var _current_dialog_box: DialogBox
var _next_node : String = ""

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
	if not Engine.is_editor_hint(): # If is running in game
		_load_dialog_data(dialog_file)
		if play_on_ready:
			await get_tree().create_timer(0.1).timeout
			start(start_id)

func _load_dialog_data(path: String) -> void:
	# Load dialog data from dialog file
	if path.is_empty(): return
	if not FileAccess.file_exists(path):
		printerr("[DialogPlayer] Dialog file '" + path + "' does not exist.")
		dialog_file = ""
		return
	var data = GDialogsJSONFileManager.load_file(path)
	if not data.has("dialog_data"): # If JSON does not contains dialog data
		printerr("[DialogPlayer] Dialog file " + path + "has an invalid format.")
		dialog_file = ""
		return
	_nodes_data = data["dialog_data"]["nodes_data"]

#region --- Editor properties ---
func _get_property_list():
	# Set new properties on editor
	if Engine.is_editor_hint():
		var props = []
		if not dialog_file.is_empty():
			# Set available dialogs IDs to select
			var id_list = ""
			for id in _dialogs_ids:
				id_list += id
				if id != _dialogs_ids[-1]:
					id_list += ","
			props.append({
				"name": &"start_id",
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": id_list
			})
			if not start_id.is_empty():
				# Set characters options
				props.append({
				"name": "Characters Settings",
				"type": TYPE_STRING,
				"usage": PROPERTY_USAGE_GROUP,
				"hint_string": "char_",
				})
				for char in _chars_keys:
					props.append({
						"name": char,
						"type": TYPE_STRING,
						"usage": PROPERTY_USAGE_SUBGROUP,
						"hint_string": char,
					})
					props.append({
						"name": char + "_portrait_display",
						"type": TYPE_NODE_PATH,
						"hint": PROPERTY_HINT_NODE_PATH_VALID_TYPES,
						"hint_string": "TextureRect,Sprite2D",
					})
					props.append({
						"name": char + "_dialogue_box",
						"type": TYPE_NODE_PATH,
						"hint": PROPERTY_HINT_NODE_PATH_VALID_TYPES,
						"hint_string": "DialogBox",
					})
		return props

func _get(property: StringName):
	# Get new properties value to show in inspector
	if property.ends_with("_portrait_display"):
		# Show the portrait display node path by character
		var char_name = property.get_slice("_portrait_", 0)
		return _portrait_displays[char_name]
	
	if property.ends_with("_dialogue_box"):
		# Show the dialogue box node path by character
		var char_name = property.get_slice("_dialogue_", 0)
		return _dialogue_boxes[char_name]

func _set(property: StringName, value: Variant) -> bool:
	# Set new properties value behaviour
	if property.ends_with("_portrait_display"):
		# Storing the portrait display node path by character
		var char_name = property.get_slice("_portrait_", 0)
		_portrait_displays[char_name] = value
		return true
	if property.ends_with("_dialogue_box"):
		# Storing the dialogue box node path by character
		var char_name = property.get_slice("_dialogue_", 0)
		_dialogue_boxes[char_name] = value
		return true
	return false

func _get_dialogs_ids() -> void:
	# Get the dialog ids from dialog file
	_dialogs_ids = []
	for dialog in _nodes_data:
		# Get all dialogs start ids
		if dialog == "unplugged_nodes": continue
		_dialogs_ids.append(dialog.replace("DIALOG_", ""))

func _get_dialog_characters(dialog_id: String) -> Array:
	# Get the characters in dialog tree 
	_chars_keys = []
	var dialog = "DIALOG_" + dialog_id
	
	for node in _nodes_data[dialog]:
		# Get characters from dialogue nodes
		if _nodes_data[dialog][node]["node_type"] == "dialogue_node":
			if not _chars_keys.has(_nodes_data[dialog][node]["char_key"]):
				_chars_keys.append(_nodes_data[dialog][node]["char_key"])
	return _chars_keys

func _create_characters_dict() -> Dictionary:
	# Create a dictionary with the characters in the selected dialog
	var dict = {}
	for char in _chars_keys:
		dict[char] = {}
	return dict
#endregion

func start(id: String = start_id) -> void:
	# Start processing a dialog tree by id
	if not _dialogs_ids.has(id):
		printerr("[DialogPlayer] Cannot find '" + id + "' ID on dialog file.")
		return
	# Search for start node and start processing from connected node
	_is_running = true
	var dialog = "DIALOG_" + id
	for node in _nodes_data[dialog]:
		if node.contains("start_node"):
			_process_node(_nodes_data[dialog][node]["to_node"][0])
			break

func stop() -> void:
	# Stop processing the dialog tree
	_is_running = false
	dialog_ended.emit()

func is_running() -> bool:
	return _is_running

func _process_node(node_name: String) -> void:
	# Process the next node on dialog tree
	if not _is_running: return
	if node_name == 'END':
		stop()
		return
	
	var node_type = node_name.split("node")[0] + "node"
	NodesReferences.nodes[node_type].parser.process_node(
		_nodes_data["DIALOG_" + start_id][node_name]
		)

func _on_dialogue_processed(char: String, dialog: String, next_node : String) -> void:
	# When dialogue node was processed by parser, play the dialog
	_next_node = next_node
	var dialog_box = get_node(_dialogue_boxes[char])
	
	if _current_dialog_box and dialog_box != _current_dialog_box:
		# When changing the dialog box, the previous one is closed
		_current_dialog_box.end_dialog()
	
	_current_dialog_box = dialog_box
	if not _current_dialog_box.is_connected("continue_dialog", _on_continue_dialog):
		_current_dialog_box.connect("continue_dialog", _on_continue_dialog)
	
	_current_dialog_box.play_dialog(char, dialog, self)

func _on_continue_dialog() -> void:
	_process_node(_next_node)

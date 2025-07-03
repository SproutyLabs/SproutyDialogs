@tool
@icon("res://addons/graph_dialogs/icons/icon.svg")
class_name DialogPlayer
extends Node

## -----------------------------------------------------------------------------
## Dialog Player
##
## It reads a dialog file and processes the dialog tree to play the dialogues.
## The dialog tree is composed of nodes that represent dialogues and actions.
## The player processes the nodes and plays the dialogues in the dialog boxes.
## -----------------------------------------------------------------------------

## Signal emitted when the dialog is started.
signal dialog_started(start_id: String)
## Signal emitted when the dialog is ended.
signal dialog_ended

## Dialog Data resource to play.
@export var dialog_data: GraphDialogsDialogueData:
	set(value):
		dialog_data = value
		_starts_ids = value.get_start_ids()
		notify_property_list_changed()

## Start ID of the dialog to play.
var start_id: String:
	set(value):
		start_id = value
		if dialog_data: # Set dictionaries to store the nodes references
			for char in dialog_data.characters[value]:
				_portrait_parents[char] = null
				_dialog_box_parents[char] = null
		notify_property_list_changed()

## Play the dialog when the node is ready.
@export var play_on_ready: bool = false

## Array to store the start IDs of the dialogues.
var _starts_ids: Array[String] = []

## Dictionary to store the portrait parent nodes by character.
var _portrait_parents: Dictionary = {}
## Dictionary to store the dialog box parent nodes by character.
var _dialog_box_parents: Dictionary = {}

## Current dialog box to display the dialog.
var _current_dialog_box: DialogBox

## Next node to process in the dialog tree after a dialogue node.
var _next_node: String = ""

## Dialog parser instance to process the dialog nodes.
var _dialog_parser: DialogParser

## Flag to control if the dialog is running.
var _is_running: bool = false


func _enter_tree() -> void:
	# Initialize dialog parser
	_dialog_parser = DialogParser.new()
	add_child(_dialog_parser)
	
	_dialog_parser.continue_to_node.connect(_process_node)
	_dialog_parser.dialogue_processed.connect(_on_dialogue_processed)


func _ready() -> void:
	# Play the dialog on ready if the property is set
	if not Engine.is_editor_hint():
		GraphDialogs.load_resources(dialog_data, start_id,
				_portrait_parents, _dialog_box_parents)
		if play_on_ready: start()


#region === Editor properties ==================================================
## Set extra properties on editor
func _get_property_list():
	if Engine.is_editor_hint():
		var props = []
		# Set available start IDs to select
		if dialog_data:
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
				"name": "Anchors Settings",
				"type": TYPE_STRING,
				"usage": PROPERTY_USAGE_GROUP,
				"hint_string": "char_",
				})
				for char in dialog_data.characters[start_id]:
					props.append({ # Set a group by character name
						"name": char.capitalize(),
						"type": TYPE_STRING,
						"usage": PROPERTY_USAGE_SUBGROUP,
						"hint_string": char,
					})
					props.append({ # Set portrait parent node path by character
						"name": char + "_portraits_parent",
						"type": TYPE_OBJECT,
						"hint": PROPERTY_HINT_NODE_TYPE,
						"hint_string": "Node",
					})
					props.append({ # Set dialogue box node path by character
						"name": char + "_dialog_box_parent",
						"type": TYPE_OBJECT,
						"hint": PROPERTY_HINT_NODE_TYPE,
						"hint_string": "Node",
					})
		return props


func _get(property: StringName):
	# Show the portrait parent node path by character
	if property.ends_with("_portraits_parent"):
		var char_name = property.get_slice("_portraits_", 0)
		return _portrait_parents[char_name]

	# Show the dialogue box node path by character
	if property.ends_with("_dialog_box_parent"):
		var char_name = property.get_slice("_dialog_", 0)
		return _dialog_box_parents[char_name]


func _set(property: StringName, value: Variant) -> bool:
	# Storing the portrait parent node path by character
	if property.ends_with("_portraits_parent"):
		var char_name = property.get_slice("_portraits_", 0)
		_portrait_parents[char_name] = value
		return true
	
	# Storing the dialogue box node path by character
	if property.ends_with("_dialog_box_parent"):
		var char_name = property.get_slice("_dialog_", 0)
		_dialog_box_parents[char_name] = value
		return true
	return false

#endregion

#region === Process dialog =====================================================

## Start processing a dialog tree by ID
func start(dialog_id: String = start_id) -> void:
	if not dialog_data: # Check if dialog data is set
		printerr("[Graph Dialogs] No dialog data set to play.")
		return
	if not _starts_ids.has(dialog_id): # Check if the dialog with given id exists
		printerr("[Graph Dialogs] Cannot find '" + dialog_id + "' ID on dialog file.")
		return

	# Search for start node and start processing from there
	for node in dialog_data.graph_data[dialog_id]:
		if node.contains("start_node"):
			print("[Graph Dialogs] Starting dialog with ID: " + dialog_id)
			_is_running = true
			_process_node(node)
			dialog_started.emit(dialog_id)
			break


## Stop processing the dialog tree
func stop() -> void:
	_is_running = false
	dialog_ended.emit()


## Check if the dialog is running
func is_running() -> bool:
	return _is_running


## Process the next node on dialog tree
func _process_node(node_name: String) -> void:
	if not _is_running: return
	# Check if the node is the end node
	if node_name == 'END':
		stop()
		return
	# Get the node type to process
	var node_type = node_name.split("_node_")[0] + "_node"
	_dialog_parser.node_processors[node_type].call(
		dialog_data.graph_data[start_id][node_name]
		)


## Play the dialog when the dialogue node is processed
func _on_dialogue_processed(char: String, portrait: String, dialog: String, next_node: String) -> void:
	_next_node = next_node
	_update_dialog_box(char)
	
	_current_dialog_box.play_dialog(char, dialog, self)


## Update the dialog box for the current character
func _update_dialog_box(character_name: String) -> void:
	var dialog_box = GraphDialogs.get_dialog_box(start_id, character_name)
	
	# Check if the dialog box is already playing a dialog
	if _current_dialog_box and dialog_box != _current_dialog_box:
		_current_dialog_box.end_dialog() # End the current dialog
	
	_current_dialog_box = dialog_box

	# Connect the dialog box signals
	if not _current_dialog_box.is_connected("continue_dialog", _on_continue_dialog):
		_current_dialog_box.continue_dialog.connect(_on_continue_dialog)


## Continue to the next node in the dialog tree
func _on_continue_dialog() -> void:
	_process_node(_next_node)

#endregion

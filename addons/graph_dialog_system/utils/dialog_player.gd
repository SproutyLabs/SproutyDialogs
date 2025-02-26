@tool
@icon("res://addons/graph_dialog_system/icons/icon.svg")
class_name DialogPlayer
extends Node

## ------------------------------------------------------------------
## Class to run a dialog tree
## ------------------------------------------------------------------

signal dialog_started(id: String)
signal dialog_ended

@export_file("*.json") var dialog_file : String :
	set(value):
		dialog_file = value
		_load_dialog_data(value)
@export var dialog_id : String
@export var dialog_box : DialogBox

var _is_running : bool = false
var _nodes_data : Dictionary
var _dialogs_ids : Array[String] = []

func _ready() -> void:
	if _nodes_data.is_empty():
		_load_dialog_data(dialog_file)
	
	for parser in NodesReferences.nodes_parsers:
		if parser != null:
			parser.connect("continue_to_node", _process_dialog_node)

func _load_dialog_data(path : String) -> void:
	# Load dialog data from dialog file
	if path.is_empty(): return
	
	if not FileAccess.file_exists(path):
		printerr("[DialogPlayer] Dialog file '" + path + "' does not exist.")
		return
	
	var data = GDialogsJSONFileManager.load_file(path)
	
	if not data.has("dialog_data"): # If JSON does not contains dialog data
		printerr("[DialogPlayer] Dialog file " + path + "has an invalid format.")
		return
	
	_nodes_data = data["dialog_data"]["nodes_data"]
	_set_dialog_data()

func _set_dialog_data() -> void:
	# Set the dialog data for process
	for dialog in _nodes_data:
		# Get all dialogs start ids
		if dialog == "unplugged_nodes": continue
		_dialogs_ids.append(dialog.replace("DIALOG_", ""))

func start(id : String = dialog_id) -> void:
	# Start processing a dialog tree by id
	if not _dialogs_ids.has(id):
		printerr("[DialogPlayer] Cannot find '" + id + "' ID on dialog file.")
		return
	# Search for start node and start processing from connected node
	for node in _nodes_data[id]:
		if node.contains("start_node"):
			var next_name = _nodes_data[id][node]["to_node"][0]
			var next_node = _nodes_data[id][next_name]
			_process_dialog_node(next_node)
			break

func stop() -> void:
	# Stop processing the dialog tree
	_is_running = false
	dialog_ended.emit()

func is_running() -> bool:
	return _is_running

func _process_dialog_node(node_name : String) -> void:
	# Process the next node on dialog tree
	if not _is_running: return
	if node_name == 'END':
		stop()
		return
	
	var node_id = _nodes_data[node_name]["node_type_id"]
	NodesReferences.nodes_parsers[node_id].process_node(_nodes_data[node_name])

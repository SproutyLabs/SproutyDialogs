@tool
extends GraphEdit

## -----------------------------------------------------------------------------
## Graph controller
##
## This script handles the graph edition, nodes creation and deletion, and
## nodes connections. It also provides methods to get and load the nodes data.
## -----------------------------------------------------------------------------

## Triggered when the graph is modified
signal modified
## Triggered when all the nodes are loaded
signal nodes_loaded

## Path to the nodes folder.
const NODES_PATH = "res://addons/graph_dialogs/nodes/"

## Text editor reference
@export var text_editor: Panel

## Alerts container
@onready var alerts: VBoxContainer = $Alerts
## Add node pop-up menu
@onready var _add_node_menu: PopupMenu = $AddNodeMenu

## Nodes references
var _nodes_references: Dictionary
## Nodes type count
var _nodes_type_count: Dictionary = {}

## Requested connection node
var _request_node: String = ""
## Requested connection port
var _request_port: int = -1

## Cursor position
var _cursor_pos: Vector2 = Vector2.ZERO


func _ready():
	_nodes_references = _get_nodes_references(NODES_PATH)
	for node in _nodes_references: # Initialize nodes count array
		_nodes_type_count[node] = 0
	set_add_node_menu()


func _input(_event):
	if (not _add_node_menu.visible) and _request_port > -1:
		_request_node = ''
		_request_port = -1


## Emit the modified signal
func on_modified():
	modified.emit()


#region === Get and Load Nodes Data ============================================

## Get nodes data in a dictionary
func get_nodes_data() -> Dictionary:
	var dict := {
		"nodes_data": {},
		"dialogs": {}
	}
	for child in get_children():
		if child is BaseNode:
			# Get dialogs texts from dialogue nodes
			if child.node_type == "dialogue_node":
				dict["dialogs"][child.get_dialog_translation_key()] = child.get_dialogs_text()
			
			if child.node_type == "start_node":
				# Start nodes define dialogs trees
				dict["nodes_data"]["DIALOG_" + child.get_start_id()] = {}
				dict["nodes_data"]["DIALOG_" + child.get_start_id()].merge(child.get_data())
			elif child.start_node == null:
				# Nodes without connection do not have a dialog tree associated
				if not dict["nodes_data"].has("unplugged_nodes"):
					dict["nodes_data"]["unplugged_nodes"] = {}
				dict["nodes_data"]["unplugged_nodes"].merge(child.get_data())
			else:
				# Any other node belongs to a dialog tree
				if not dict["nodes_data"].has("DIALOG_" + child.get_start_id()):
					dict["nodes_data"]["DIALOG_" + child.get_start_id()] = {}
				dict["nodes_data"]["DIALOG_" + child.get_start_id()].merge(child.get_data())
	return dict


## Load nodes data from a dictionary
func load_nodes_data(data: Dictionary, dialogs: Dictionary) -> void:
	for node_group in data["dialog_data"]["nodes_data"]:
		for node_name in data["dialog_data"]["nodes_data"][node_group]:
			# Get node data
			var node_data = data.dialog_data.nodes_data.get(node_group).get(node_name)
			_nodes_type_count[node_data["node_type"]] += 1

			# Create node and set data
			var new_node = _nodes_references[node_data["node_type"]].instantiate()
			new_node.title += ' #' + str(node_data["node_index"])
			new_node.name = node_name
			add_child(new_node, true)
			new_node.set_data(node_data)
			
			# Load dialogs on dialogue nodes
			if node_data["node_type"] == "dialogue_node":
				new_node.load_dialogs(dialogs[node_data["dialog_key"]])
			
	# When all the nodes are loaded, notify the nodes to connect each other
	nodes_loaded.emit()


## Get the nodes scene references from the nodes folder
func _get_nodes_references(path: String) -> Dictionary:
	var nodes_dict = {}
	var nodes_scenes = DirAccess.get_files_at(NODES_PATH)
	for node in nodes_scenes:
		if node.ends_with(".tscn"):
			var node_name = node.replace(".tscn", "")
			nodes_dict[node_name] = load(NODES_PATH + node)
	return nodes_dict

#endregion

#region === Add and Delete Nodes ===============================================

## Set nodes list on popup node menu
func set_add_node_menu() -> void:
	_add_node_menu.clear()
	var index = 0
	for node in _nodes_references:
		var node_aux = _nodes_references[node].instantiate()
		_add_node_menu.add_icon_item(node_aux.node_icon, node_aux.name.capitalize(), index)
		_add_node_menu.set_item_metadata(index, node)
		node_aux.queue_free()
		index += 1


## Show add node pop-up menu
func show_add_node_menu(pos: Vector2) -> void:
	var pop_pos := pos + global_position + Vector2(get_window().position)
	_add_node_menu.popup(Rect2(pop_pos.x, pop_pos.y, _add_node_menu.size.x, _add_node_menu.size.y))
	_cursor_pos = (pos + scroll_offset) / zoom


## Add a new node to the graph
func add_new_node(node_type: String) -> void:
	# Create a new node of the given type
	_nodes_type_count[node_type] += 1
	var new_node = _nodes_references[node_type].instantiate()
	new_node.name += "_" + str(_nodes_type_count[node_type])
	new_node.title += ' #' + str(_nodes_type_count[node_type])
	new_node.node_index = _nodes_type_count[node_type]
	new_node.position_offset = _cursor_pos
	new_node.selected = true
	add_child(new_node, true)
	on_modified()
	
	# Connect to a previous node if requested
	if _request_port > -1 and new_node.is_slot_enabled_left(0):
		var prev_connection := get_node_output_connections(_request_node, _request_port)
		if prev_connection.size() > 0:
			disconnect_node(_request_node, _request_port,
				prev_connection[0]['to_node'], prev_connection[0]['to_port'])
			get_node(prev_connection[0]["to_node"]).start_node = null
		
		connect_node(_request_node, _request_port, new_node.name, 0)
		new_node.start_node = get_node(_request_node).start_node
		_request_node = ""
		_request_port = -1


## Delete a node from graph
func delete_node(node: GraphNode) -> void:
	var node_connections = get_node_connections(node.name, true)
	for connection in node_connections: # Disconnect all connections
		disconnect_node(connection["from_node"], connection["from_port"],
			connection["to_node"], connection["to_port"])
	_nodes_type_count[node.node_type] -= 1
	node.queue_free() # Remove node
	on_modified()


## Show add node pop-up menu on right click
func _on_right_click(pos: Vector2) -> void:
	show_add_node_menu(pos)


## Add node from pop-up menu
func _on_add_node_menu_selected(id: int) -> void:
	var node_type = _add_node_menu.get_item_metadata(id)
	add_new_node(node_type)


## Delete selected nodes
func _on_delete_nodes_request(nodes: Array[StringName]):
	for child in get_children():
		for node_name in nodes: # Remove selected nodes
			if child.name == node_name: delete_node(child)


## Check if graph do not have nodes
func is_graph_empty() -> bool:
	for child in get_children():
		if child is BaseNode:
			return false
	return true


## Clear graph removing the current nodes
func clear_graph() -> void:
	for child in get_children():
		if child is BaseNode:
			child.queue_free()
#endregion

#region === Nodes Connection ===================================================

## Return the output or input connections of a given node
func get_node_connections(node: String, all: bool = false, out: bool = true) -> Array:
	var all_connections = get_connection_list()
	var node_connections = []
	
	for connection in all_connections:
		if connection["from_node"] == node and (all or out):
			node_connections.append(connection)
		if connection["to_node"] == node and (all or !out):
			node_connections.append(connection)
	return node_connections


## Return the connections from a node on the given output port
func get_node_output_connections(node: String, port: int) -> Array:
	var node_connections = get_node_connections(node)
	var port_connections = []

	for connection in node_connections:
		if connection["from_node"] == node and connection["from_port"] == port:
			port_connections.append(connection)
	return port_connections


## Disconnect a output connection from a node on the given port
func disconnect_node_on_port(node: String, port: int) -> void:
	var port_connections = get_node_output_connections(node, port)
	for connection in port_connections:
		disconnect_node(connection["from_node"], connection["from_port"],
			connection["to_node"], connection["to_port"])
		get_node(connection["to_node"]).start_node = null
	on_modified()


## Connect two nodes on the given ports
func _on_connection_request(from_node: String, from_port: int, to_node: String, to_port: int) -> void:
	var prev_connection = get_node_output_connections(from_node, from_port)
	
	if prev_connection.size() > 0:
		# Limit the connections to one, diconnecting the old one
		disconnect_node(from_node, from_port, prev_connection[0]["to_node"], prev_connection[0]["to_port"])
		get_node(prev_connection[0]["to_node"]).start_node = null
	
	# Handle nodes connection and assign the node to the connected dialog tree
	connect_node(from_node, from_port, to_node, to_port)
	get_node(to_node).start_node = get_node(from_node).start_node
	on_modified()


## If connection ends on empty space, show add node menu to add a new node
func _on_connection_to_empty(from_node: String, from_port: int, release_position: Vector2):
	_request_node = from_node
	_request_port = from_port
	show_add_node_menu(release_position)
#endregion

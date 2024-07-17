@tool
extends GraphEdit

@export var nodes_scenes: Array[PackedScene] = [
	preload("res://addons/graph_dialog_system/nodes/start_node.tscn"),
	preload("res://addons/graph_dialog_system/nodes/comment_node.tscn"),
	preload("res://addons/graph_dialog_system/nodes/dialogue_node.tscn"),
	preload("res://addons/graph_dialog_system/nodes/choices_node.tscn"),
	preload("res://addons/graph_dialog_system/nodes/condition_node.tscn"),
	preload("res://addons/graph_dialog_system/nodes/set_variable_node.tscn"),
	preload("res://addons/graph_dialog_system/nodes/signal_node.tscn"),
	preload("res://addons/graph_dialog_system/nodes/jump_node.tscn"),
	preload("res://addons/graph_dialog_system/nodes/wait_node.tscn"),
	preload("res://addons/graph_dialog_system/nodes/end_node.tscn"),
]

@onready var add_node_menu : PopupMenu = $AddNodeMenu
var cursor_pos : Vector2 = Vector2.ZERO

func _ready():
	pass # Replace with function body.

#region Input ------------------------------------------------------------------
func _on_right_click(pos : Vector2):
	# Handle when do right click on graph canvas
	cursor_pos = (pos + scroll_offset) / zoom
	show_add_node_menu(pos)

func _on_add_menu_node_selected(id : int):
	add_node(id)
#endregion

#region Nodes ------------------------------------------------------------------
func show_add_node_menu(pos : Vector2):
	# Show add node pop-up menu
	var pop_pos := pos + global_position + Vector2(get_window().position)
	add_node_menu.popup(Rect2(pop_pos.x, pop_pos.y, add_node_menu.size.x, add_node_menu.size.y))

func add_node(typeID : int):
	# Create a new node
	var new_node := nodes_scenes[typeID].instantiate()
	new_node.name += "_" + str(get_child_count())
	new_node.title += ' #' + new_node.name.split('_')[1]
	new_node.position_offset = cursor_pos
	new_node.selected = true
	add_child(new_node, true)

func get_node_connections(node : String):
	# Return the connections of a given node
	var all_connections = get_connection_list()
	var node_connections = []
	for connection in all_connections:
		if connection["from_node"] == node:
			node_connections.append(connection)
	return node_connections

func get_node_connections_on_port(node: String, port : int):
	# Return the connections from a node on the given port
	var node_connections = get_node_connections(node)
	var port_connections = []
	for connection in node_connections:
		if connection["from_node"] == node and connection["from_port"] == port:
			port_connections.append(connection)
	return port_connections

func disconnect_node_connections_on_port(node: String, port : int):
	# Disconnect a connection from a node on the given port
	var port_connections = get_node_connections_on_port(node, port)
	for connection in port_connections:
		disconnect_node(connection["from_node"], connection["from_port"],
			connection["to_node"], connection["to_port"])
	
func _on_nodes_connection_request(from_node, from_port, to_node, to_port):
	# Handle nodes connection
	var from_node_type = from_node.split("_")[0]
	var to_node_type = to_node.split("_")[0]
	
	print("from: " + from_node_type + " (slot " + str(from_port) + ") to: " + to_node_type +" (slot "+ str(to_port) +")")
	
	if from_node_type == "DialogueNode" and from_port == 0 and to_node_type != "ChoicesNode":
		printerr("[DialogueSystem] Dialogue node choices only can be connect to a choices node!")
		return
	
	connect_node(from_node, from_port, to_node, to_port)
#endregion

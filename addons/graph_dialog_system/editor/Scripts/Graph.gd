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
	preload("res://addons/graph_dialog_system/nodes/wait_node.tscn"),
]
@export var titlebar_icons : Array[CompressedTexture2D] = [
	preload("res://addons/graph_dialog_system/icons/Remove.svg"),
	preload("res://addons/graph_dialog_system/icons/Play.svg"),
	preload("res://addons/graph_dialog_system/icons/Pin.svg"),
	preload("res://addons/graph_dialog_system/icons/Script.svg"),
	preload("res://addons/graph_dialog_system/icons/ClassList.svg"),
	preload("res://addons/graph_dialog_system/icons/AnimationTrackGroup.svg"),
	preload("res://addons/graph_dialog_system/icons/EditAddRemove.svg"),
	preload("res://addons/graph_dialog_system/icons/Signals.svg"),
	preload("res://addons/graph_dialog_system/icons/Timer.svg")
]

@onready var add_node_menu : PopupMenu = $AddNodeMenu
var cursor_pos : Vector2 = Vector2.ZERO

func _ready():
	pass # Replace with function body.

#region --- Input --------------------------------------------------------------
func _on_right_click(pos : Vector2) -> void:
	# Handle when do right click on graph canvas
	cursor_pos = (pos + scroll_offset) / zoom
	show_add_node_menu(pos)

func _on_add_menu_node_selected(id : int) -> void:
	add_node(id)
#endregion

#region --- Nodes --------------------------------------------------------------
func show_add_node_menu(pos : Vector2) -> void:
	# Show add node pop-up menu
	var pop_pos := pos + global_position + Vector2(get_window().position)
	add_node_menu.popup(Rect2(pop_pos.x, pop_pos.y, add_node_menu.size.x, add_node_menu.size.y))

func add_node(typeID : int) -> void:
	# Create a new node
	var new_node := nodes_scenes[typeID].instantiate()
	new_node.name += "_" + str(get_child_count())
	new_node.title += ' #' + new_node.name.split('_')[1]
	new_node.position_offset = cursor_pos
	set_node_titlebar(new_node, typeID)
	new_node.selected = true
	add_child(new_node, true)

func set_node_titlebar(node : GraphNode, typeID : int) -> void:
	# Add buttons to node titlebar
	var node_titlebar = node.get_titlebar_hbox()
	
	# Add node type icon
	var node_icon = TextureButton.new()
	node_icon.texture_normal = titlebar_icons[typeID + 1]
	node_icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	node_titlebar.add_child(node_icon)
	node_titlebar.move_child(node_icon, 0)
	
	# Add remove node button
	var remove_button = TextureButton.new()
	remove_button.texture_normal = titlebar_icons[0]
	remove_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	remove_button.connect("pressed", remove_node.bind(node))
	node_titlebar.add_child(remove_button)

func remove_node(node : GraphNode) -> void:
	# Delete a node from graph
	var node_connections = get_node_connections(node.name, true)
	for connection in node_connections: # Disconnect all connections
		disconnect_node(connection["from_node"], connection["from_port"],
			connection["to_node"], connection["to_port"])
	print("Removed node: "+ node.name)
	node.queue_free() # Remove node
#endregion

#region --- Nodes Connection ---------------------------------------------------
func get_node_connections(node : String, all : bool = false, out : bool = true) -> Array:
	# Return the output or input connections of a given node
	var all_connections = get_connection_list()
	var node_connections = []
	for connection in all_connections:
		if connection["from_node"] == node and (all or out):
			node_connections.append(connection)
		if connection["to_node"] == node and (all or !out):
			node_connections.append(connection)
	return node_connections

func get_node_output_connections(node: String, port : int) -> Array:
	# Return the connections from a node on the given output port
	var node_connections = get_node_connections(node)
	var port_connections = []
	for connection in node_connections:
		if connection["from_node"] == node and connection["from_port"] == port:
			port_connections.append(connection)
	return port_connections

func disconnect_node_on_port(node: String, port : int) -> void:
	# Disconnect a output connection from a node on the given port
	var port_connections = get_node_output_connections(node, port)
	for connection in port_connections:
		disconnect_node(connection["from_node"], connection["from_port"],
			connection["to_node"], connection["to_port"])
	
func _on_nodes_connection_request(from_node, from_port, to_node, to_port) -> void:
	connect_node(from_node, from_port, to_node, to_port) # Handle nodes connection
#endregion

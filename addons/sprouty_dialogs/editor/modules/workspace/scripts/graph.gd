@tool
extends GraphEdit

# -----------------------------------------------------------------------------
# Graph controller
# -----------------------------------------------------------------------------
## This script handles the graph edition, nodes creation and deletion, and
## nodes connections. It also provides methods to get and load the nodes data.
# -----------------------------------------------------------------------------

## Triggered when the graph is modified
signal modified
## Triggered when all the nodes are loaded
signal nodes_loaded

## Emitted when is requesting to open a character file
signal open_character_file_request(path: String)
## Emitted when is requesting to play a dialog from a start node
signal play_dialog_request(start_id: String)

## Emitted when a expand button to open the text editor is pressed
signal open_text_editor(text_box: TextEdit)
## Emitted when change the focus to another text box while the text editor is open
signal update_text_editor(text_box: TextEdit)

## Emitted when the locales are changed
signal locales_changed
## Emitted when the translation enabled state is changed
signal translation_enabled_changed(enabled: bool)

## Path to the nodes folder.
const NODES_PATH = "res://addons/sprouty_dialogs/nodes/"

## Alerts container
@onready var alerts: VBoxContainer = $Alerts
## Add node pop-up menu
@onready var _add_node_menu: PopupMenu = $AddNodeMenu
## Node actions pop-up menu
@onready var _node_actions_menu: PopupMenu = $NodeActionsMenu

## Nodes references
var _nodes_references: Dictionary

## Selected nodes
var _selected_nodes: Array[GraphNode] = []
## Nodes copied to clipboard
var _nodes_copy: Array[GraphNode] = []
## Copied nodes references
var _copied_nodes: Dictionary = {}
## Copied names references
var _copied_names: Dictionary = {}
## Copied connections references
var _copied_connections: Dictionary = {}

## Requested connection node
var _request_node: String = ""
## Requested connection port
var _request_port: int = -1

## Cursor position
var _cursor_pos: Vector2 = Vector2.ZERO


func _init() -> void:
	node_selected.connect(_on_node_selected)
	node_deselected.connect(_on_node_deselected)

	copy_nodes_request.connect(_on_copy_nodes)
	cut_nodes_request.connect(_on_cut_nodes)
	paste_nodes_request.connect(_on_paste_nodes)
	duplicate_nodes_request.connect(_on_duplicate_nodes)
	delete_nodes_request.connect(_on_delete_nodes_request)

	connection_request.connect(_on_connection_request)
	connection_to_empty.connect(_on_connection_to_empty)
	popup_request.connect(_on_right_click)


func _ready():
	_add_node_menu.id_pressed.connect(_on_add_node_menu_selected)
	_node_actions_menu.id_pressed.connect(_on_node_actions_menu_selected)

	_nodes_references = _get_nodes_references(NODES_PATH)
	set_node_actions_menu()
	set_add_node_menu()


func _input(_event):
	if (not _add_node_menu.visible) and _request_port > -1:
		_request_node = ''
		_request_port = -1


## Emit the modified signal
func on_modified(_arg: Variant = null) -> void:
	modified.emit()


## Notify the nodes that the locales have changed
func on_locales_changed():
	locales_changed.emit()


## Notify the nodes that the translation enabled state has changed
func on_translation_enabled_changed(enabled: bool):
	translation_enabled_changed.emit(enabled)


# Create a new node of a given type
func _new_node(node_type: String, node_index: int, node_offset: Vector2, add_to_count: bool = true) -> GraphNode:
	var new_node = _nodes_references[node_type].instantiate()
	new_node.name = node_type + "_" + str(node_index)
	new_node.title += ' #' + str(node_index)
	new_node.position_offset = node_offset
	new_node.node_index = node_index
	new_node.node_type = node_type
	add_child(new_node, true)

	# Connect translation signals
	if node_type == "dialogue_node" or node_type == "options_node":
		locales_changed.connect(new_node.on_locales_changed)
		translation_enabled_changed.connect(new_node.on_translation_enabled_changed)
	return new_node


## Get the nodes scene references from the nodes folder
func _get_nodes_references(path: String) -> Dictionary:
	var nodes_dict = {}
	var nodes_scenes = DirAccess.get_files_at(NODES_PATH)
	for node in nodes_scenes:
		if node.ends_with(".tscn"):
			var node_name = node.replace(".tscn", "")
			nodes_dict[node_name] = load(NODES_PATH + node)
	return nodes_dict


## Get the next available index for a node type
## This is used to ensure that the node index is unique
func get_next_available_index(node_type: String) -> int:
	var used_indices := []
	for child in get_children():
		if child is SproutyDialogsBaseNode and child.node_type == node_type:
			used_indices.append(child.node_index)
	# Find the lowest missing index starting from 1
	var idx := 1
	while idx in used_indices:
		idx += 1
	return idx


#region === Graph Data =========================================================
## Get graph data in a dictionary
func get_graph_data() -> Dictionary:
	var dict := {
		"nodes_data": {},
		"dialogs": {},
		"characters": {}
	}
	for child in get_children():
		if child is SproutyDialogsBaseNode:
			var start_id = child.get_start_id()

			# Get dialogs and characters from dialogue nodes
			if child.node_type == "dialogue_node":
				dict.dialogs[child.get_dialog_translation_key()] = child.get_dialogs_text()
				var character = child.get_character_name()
				if not dict.characters.has(start_id):
					dict.characters[start_id] = {}
					
				# Add character to the reference dictionary
				if character != "" and not dict.characters[start_id].has(character):
						dict.characters[start_id][character] = \
							ResourceSaver.get_resource_id_for_path(child.get_character_path())
			
			# Get option dialogs from options nodes
			if child.node_type == "options_node":
				var options = child.get_options_text()
				for option in options:
					dict.dialogs.merge(option)
			
			# Start nodes define dialogs trees
			if child.node_type == "start_node":
				if not dict.nodes_data.has(start_id):
					dict.nodes_data[start_id] = {}
				dict.nodes_data[start_id].merge(child.get_data())
			# Nodes without connection do not have a dialog tree associated
			elif child.start_node == null:
				if not dict.nodes_data.has("unplugged_nodes"):
					dict.nodes_data["unplugged_nodes"] = {}
				dict.nodes_data["unplugged_nodes"].merge(child.get_data())
			else: # Any other node belongs to a dialog tree
				if not dict.nodes_data.has(start_id):
					dict.nodes_data[start_id] = {}
				dict.nodes_data[start_id].merge(child.get_data())
	return dict


## Load graph data from a dictionary
func load_graph_data(data: SproutyDialogsDialogueData, dialogs: Dictionary) -> void:
	var characters = data.characters
	var graph_data = data.graph_data
	# Flag to fallback to resource dialogs if key not found in CSV
	var fallback_to_resource = EditorSproutyDialogsSettingsManager.get_setting("fallback_to_resource")
	for dialogue_id in graph_data.keys():
		# Find the start node for the current dialogue
		var current_start_node = ""
		for node_name in graph_data[dialogue_id].keys():
			if graph_data[dialogue_id][node_name]["node_type"] == "start_node":
				current_start_node = node_name
				break
		# Load nodes for the current dialogue
		for node_name in graph_data[dialogue_id].keys():
			var node_data = graph_data[dialogue_id][node_name]

			# Create node and set data
			var new_node = _new_node(
				node_data["node_type"],
				node_data["node_index"],
				node_data["offset"]
			)
			new_node.set_data(node_data)
			new_node.start_node_name = current_start_node
			
			# Load dialogs and characters on dialogue nodes
			if node_data["node_type"] == "dialogue_node":
				if not dialogs.has(node_data["dialog_key"]):
					# Print error if no dialog is found for the dialogue node
					printerr("[Sprouty Dialogs] No dialogue found for Dialogue Node #" + str(node_data["node_index"]) \
						+" in the CSV file: " + ResourceUID.get_id_path(data.csv_translation_file) \
						+". Check that the key '" + node_data["dialog_key"] \
						+"' exists in the CSV translation file and that it is the correct CSV file." \
						+ (" Loading '" + node_data["dialog_key"] + "' dialogue from '" \
						+ data.resource_path.get_file() + "' dialog file instead.") \
						if fallback_to_resource else "")
					if fallback_to_resource and data.dialogs.has(node_data["dialog_key"]):
						new_node.load_dialogs(data.dialogs[node_data["dialog_key"]])
				else:
					if not dialogs[node_data["dialog_key"]].has("default"): # Ensure that the default dialog exists
						dialogs[node_data["dialog_key"]]["default"] = data.dialogs[node_data["dialog_key"]]["default"]
					new_node.load_dialogs(dialogs[node_data["dialog_key"]])
				
				# Load character if exists
				var character_name = node_data["character"]
				if character_name != "":
					var character_uid = characters[dialogue_id][character_name]
					if character_uid != -1:
						new_node.load_character(ResourceUID.get_id_path(character_uid))
						new_node.load_portrait(node_data["portrait"])
				
			# Load options on options nodes
			elif node_data["node_type"] == "options_node":
				for option_key in node_data["options_keys"]:
					if not dialogs.has(option_key):
						# Print error if no dialog is found for the option
						printerr("[Sprouty Dialogs] No dialogue found for Option #" \
							+ str(int(option_key.split("_")[-1]) + 1) + " of Option Node #" \
							+ str(node_data["node_index"]) + " in the CSV file:\n" \
							+ ResourceUID.get_id_path(data.csv_translation_file) \
							+". Check that the key '" + option_key \
							+"' exists in the CSV translation file and that it is the correct CSV file." \
							+ (" Loading '" + option_key + "' dialogue from '" \
							+ data.resource_path.get_file() + "' dialog file instead.") \
							if fallback_to_resource else "")
						if fallback_to_resource and data.dialogs.has(option_key):
							dialogs[option_key] = data.dialogs[option_key]
					else:
						if not dialogs[option_key].has("default"): # Ensure that the default dialog exists
							dialogs[option_key]["default"] = data.dialogs[option_key]["default"]
				new_node.load_options_text(dialogs)
	
	# When all the nodes are loaded, notify the nodes to connect each other
	nodes_loaded.emit()

#endregion

#region === Popup Menus ========================================================

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


## Set icons on node actions menu
func set_node_actions_menu(has_selection: bool = false, paste_enabled: bool = false) -> void:
	_node_actions_menu.clear()
	_node_actions_menu.add_icon_item(get_theme_icon("Add", "EditorIcons"), "Add Node", 0)
	_node_actions_menu.add_separator()
	if has_selection:
		_node_actions_menu.add_icon_item(get_theme_icon("Remove", "EditorIcons"),
			"Remove Nodes" if _selected_nodes.size() > 1 else "Remove Node", 1)
		_node_actions_menu.add_icon_item(get_theme_icon("Duplicate", "EditorIcons"),
			"Duplicate Nodes" if _selected_nodes.size() > 1 else "Duplicate Node", 2)
		_node_actions_menu.add_icon_item(get_theme_icon("ActionCopy", "EditorIcons"),
			"Copy Nodes" if _selected_nodes.size() > 1 else "Copy Node", 3)
		_node_actions_menu.add_icon_item(get_theme_icon("ActionCut", "EditorIcons"),
			"Cut Nodes" if _selected_nodes.size() > 1 else "Cut Node", 4)
	if paste_enabled:
		_node_actions_menu.add_icon_item(get_theme_icon("ActionPaste", "EditorIcons"),
			"Paste Nodes" if _nodes_copy.size() > 1 else "Paste Node", 5)


## Rename the node actions menu items based on the number of selected nodes
func _rename_node_actions(plural: bool) -> void:
	_node_actions_menu.set_item_text(2, "Remove Nodes" if plural else "Remove Node")
	_node_actions_menu.set_item_text(3, "Duplicate Nodes" if plural else "Duplicate Node")
	_node_actions_menu.set_item_text(4, "Copy Nodes" if plural else "Copy Node")
	_node_actions_menu.set_item_text(5, "Cut Nodes" if plural else "Cut Node")
	_node_actions_menu.set_item_text(6, "Paste Nodes" if plural else "Paste Node")


## Show a pop-up menu at a given position
func _show_popup_menu(menu: PopupMenu, pos: Vector2) -> void:
	var pop_pos := pos + global_position + Vector2(get_window().position)
	menu.popup(Rect2(pop_pos.x, pop_pos.y, _add_node_menu.size.x, _add_node_menu.size.y))
	_cursor_pos = (pos + scroll_offset) / zoom
	menu.reset_size()


## Add node from pop-up menu
func _on_add_node_menu_selected(id: int) -> void:
	var node_type = _add_node_menu.get_item_metadata(id)
	add_new_node(node_type)


## Handle node actions from the pop-up menu
func _on_node_actions_menu_selected(id: int) -> void:
	match id:
		0: # Add Node
			_show_popup_menu(_add_node_menu, get_local_mouse_position())
		1: # Delete Node
			var selected_nodes = _selected_nodes.duplicate()
			for node in selected_nodes:
				delete_node(node)
		2: # Duplicate Node
			_on_duplicate_nodes()
		3: # Copy Node
			_on_copy_nodes()
		4: # Cut Node
			_on_cut_nodes()
		5: # Paste Node
			_on_paste_nodes()


## Show add node pop-up menu on right click
func _on_right_click(pos: Vector2) -> void:
	# Show node actions menu if nodes are selected
	if _selected_nodes.size() > 0:
		if _nodes_copy.size() > 0:
			set_node_actions_menu(true, true)
			_show_popup_menu(_node_actions_menu, pos)
		else:
			set_node_actions_menu(true, false)
			_show_popup_menu(_node_actions_menu, pos)
	# Show only paste option if nodes are copied but no nodes are selected
	elif _nodes_copy.size() > 0:
		set_node_actions_menu(false, true)
		_show_popup_menu(_node_actions_menu, pos)
	else: # Show add node menu if no nodes are selected
		_show_popup_menu(_add_node_menu, pos)

#endregion

#region === Nodes Operations ===================================================

## Add a new node to the graph
func add_new_node(node_type: String) -> void:
	var new_index = get_next_available_index(node_type)
	var new_node = _new_node(node_type, new_index, _cursor_pos)
	new_node.selected = true
	on_modified()
	
	# Connect to a previous node if requested
	if _request_port > -1 and new_node.is_slot_enabled_left(0):
		var prev_connection := get_node_output_connections(_request_node, _request_port)
		if prev_connection.size() > 0:
			disconnect_node(_request_node, _request_port,
				prev_connection[0]['to_node'], prev_connection[0]['to_port'])
			get_node(NodePath(prev_connection[0]["to_node"])).start_node = null
		
		connect_node(_request_node, _request_port, new_node.name, 0)
		new_node.start_node = get_node(NodePath(_request_node)).start_node
		_request_node = ""
		_request_port = -1


## Delete a node from graph
func delete_node(node: GraphNode) -> void:
	var node_connections = get_node_connections(node.name, true)
	for connection in node_connections: # Disconnect all connections
		disconnect_node(connection["from_node"], connection["from_port"],
			connection["to_node"], connection["to_port"])
	_selected_nodes.erase(node)
	node.queue_free()
	on_modified()


## Create a copy of a node from the graph
func copy_node(node: GraphNode) -> GraphNode:
	var new_node = _new_node(
		node.node_type,
		get_next_available_index(node.node_type),
		node.position_offset,
		false # Do not add to count here, it will be added later
	)
	new_node.set_data(node.get_data()[node.name.to_snake_case()])
	remove_child(new_node)

	_copied_connections[new_node.name] = get_node_connections(node.name)
	_copied_nodes[new_node.name] = node # Store the copied node reference
	_copied_names[node.name] = new_node.name # Store the copied name reference
	
	if node.node_type == "dialogue_node":
		new_node.load_dialogs(node.get_dialogs_text())
		new_node.load_character(node.get_character_path())
		new_node.load_portrait(node.get_portrait())
	return new_node


## Delete selected nodes
func _on_delete_nodes_request(nodes: Array[StringName]):
	for child in get_children():
		for node_name in nodes: # Remove selected nodes
			if child.name == node_name: delete_node(child)


## Duplicate selected nodes
func _on_duplicate_nodes() -> void:
	if _selected_nodes.size() == 0:
		return
	var _duplicate_nodes = _selected_nodes.duplicate()
	for node in _duplicate_nodes:
		var new_index = get_next_available_index(node.node_type)
		var new_node = copy_node(node)
		new_node.node_index = new_index
		new_node.name = node.node_type + "_" + str(new_index)
		new_node.title = new_node.title.split("#")[0] + "#" + str(new_index)
		_rename_if_exists(new_node)
		new_node.position_offset += Vector2(20, 20)
		add_child(new_node, true)
		new_node.selected = true
		node.selected = false
	_reconnect_nodes_copy()
	_copied_nodes.clear()
	_nodes_copy.clear()
	on_modified()


## Copy selected nodes
func _on_copy_nodes() -> void:
	_copied_connections.clear()
	_copied_names.clear()
	_copied_nodes.clear()
	_nodes_copy.clear()

	if _selected_nodes.size() == 0:
		return
	for node in _selected_nodes:
		var new_node = copy_node(node)
		_nodes_copy.append(new_node)


## Cut selected nodes
func _on_cut_nodes() -> void:
	_copied_connections.clear()
	_copied_names.clear()
	_copied_nodes.clear()
	_nodes_copy.clear()
	
	if _selected_nodes.size() == 0:
		return

	for node in _selected_nodes:
		_copied_connections[node.name] = get_node_connections(node.name)
		_copied_names[node.name] = node.name
		_copied_nodes[node.name] = node
		_nodes_copy.append(node)
		remove_child(node)
	_selected_nodes.clear()
	on_modified()


## Paste copied nodes
func _on_paste_nodes() -> void:
	if _nodes_copy.size() == 0:
		return
	
	# Get the center point of the nodes
	var center_pos = Vector2.ZERO
	for node in _nodes_copy:
		center_pos += node.position_offset
	center_pos /= _nodes_copy.size()
	
	for node in _nodes_copy:
		node.position_offset -= Vector2(node.size.x / 2, node.size.y / 2)
		node.position_offset -= center_pos # Center the nodes
		node.position_offset += ((get_local_mouse_position() + scroll_offset) / zoom)

		if _copied_nodes[node.name]: # Deselect original nodes
			_copied_nodes[node.name].selected = false
		
		var new_index = get_next_available_index(node.node_type)
		node.node_index = new_index
		node.name = node.node_type + "_" + str(new_index)
		node.title = node.title.split("#")[0] + "#" + str(new_index)
		_rename_if_exists(node)
		add_child(node, true)
		node.selected = true
	
	_reconnect_nodes_copy()
	_copied_connections.clear()
	_copied_names.clear()
	_copied_nodes.clear()
	_nodes_copy.clear()
	on_modified()


## Rename the node if it already exists
func _rename_if_exists(node: GraphNode) -> void:
	if get_node_or_null(NodePath(node.name)) != null:
		var new_index = get_next_available_index(node.node_type)
		node.name = node.node_type + "_" + str(new_index)
		node.title = node.title.split("#")[0] + "#" + str(new_index)
		node.node_index = new_index


## Reconnect nodes after a paste operation
func _reconnect_nodes_copy() -> void:
	for node in _copied_connections:
		for connection in _copied_connections[node]:
			if _copied_names.has(connection["to_node"]):
				connect_node(_copied_names[connection["from_node"]], connection["from_port"],
					_copied_names[connection["to_node"]], connection["to_port"])
	_copied_connections.clear()


## Called when a node is selected
func _on_node_selected(node: GraphNode) -> void:
	if _selected_nodes.has(node):
		return # Skip if the node is already selected
	_selected_nodes.append(node)


## Called when a node is deselected
func _on_node_deselected(node: GraphNode) -> void:
	_selected_nodes.erase(node)


## Check if graph do not have nodes
func is_graph_empty() -> bool:
	for child in get_children():
		if child is SproutyDialogsBaseNode:
			return false
	return true


## Clear graph removing the current nodes
func clear_graph() -> void:
	for child in get_children():
		if child is SproutyDialogsBaseNode:
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
		get_node(NodePath(connection["to_node"])).start_node = null
	on_modified()


## Connect two nodes on the given ports
func _on_connection_request(from_node: String, from_port: int, to_node: String, to_port: int) -> void:
	var prev_connection = get_node_output_connections(from_node, from_port)
	
	if prev_connection.size() > 0:
		# Limit the connections to one, diconnecting the old one
		disconnect_node(from_node, from_port, prev_connection[0]["to_node"], prev_connection[0]["to_port"])
		get_node(NodePath(prev_connection[0]["to_node"])).start_node = null
	
	# Handle nodes connection and assign the node to the connected dialog tree
	connect_node(from_node, from_port, to_node, to_port)
	get_node(NodePath(to_node)).start_node = get_node(NodePath(from_node)).start_node
	on_modified()


## If connection ends on empty space, show add node menu to add a new node
func _on_connection_to_empty(from_node: String, from_port: int, release_position: Vector2):
	_request_node = from_node
	_request_port = from_port
	disconnect_node_on_port(from_node, from_port) # Remove the connection
	_show_popup_menu(_add_node_menu, release_position)

#endregion

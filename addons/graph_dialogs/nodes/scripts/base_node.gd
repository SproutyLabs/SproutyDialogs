@tool
class_name BaseNode
extends GraphNode

## -----------------------------------------------------------------------------
## Base Node
##
## It provides the basic implementation to every node for the dialog system.
## -----------------------------------------------------------------------------

## Emitted when the node is processed to continue with the next node
## in the dialog tree. (When the dialog is running)
signal continue_to_node(to_node: String)

## Node color to display on the node titlebar.
@export_color_no_alpha var node_color: Color
## Icon to display on the node titlebar.
@export var node_icon: Texture2D

## Graph Editor reference.
@onready var graph_editor: GraphEdit = get_parent() as GraphEdit

## Name of the start node in the dialog tree where the node belongs.
## Used to find the start node in the graph editor on load.
var start_node_name: String = ""
## Start node of the dialog tree where the node belongs.
var start_node: BaseNode = null
## Array to store the output nodes connections.
var to_node: Array = []

## Node type name.
var node_type: String = ""
## Index of the node in the graph editor.
var node_index: int = 0


func _ready():
	# Set node type based on the node name
	node_type = name.to_snake_case().split("_node_")[0] + "_node"
	if graph_editor: # Check if the node is in the graph editor
		graph_editor.nodes_loaded.connect(_load_connections)
		_set_node_titlebar()


#region === Overrides ==========================================================

## Get the node data as a dictionary.
## This method should be overridden in each node.
func get_data() -> Dictionary:
	# Abstract method to implement in child nodes
	return {}


## Set the node data from a dictionary.
## This method should be overridden in each node.
func set_data(dict: Dictionary) -> void:
	# Abstract method to implement in child nodes
	pass


## Handle the node processing when the dialog is running.
## It should ends calling the signal [code]"continue_to_node"[/code]
## to process the next node in the dialog tree.
## It should be overridden in each node.
func process_node(node_data: Dictionary) -> void:
	# Abstract method to implement in the child nodes
	pass

#endregion


## Get the start node id of the dialog tree.
func get_start_id() -> String:
	if start_node == null: return ""
	else: return start_node.get_start_id()


## Load the connections of the node.
func _load_connections() -> void:
	if start_node_name != "": # Set start node reference
		start_node = graph_editor.get_node(start_node_name)
	
	 # Connect each output node
	for output_node in to_node:
		if output_node == "END":
			continue
		graph_editor.connect_node(name, to_node.find(output_node), output_node, 0)


## Set the node titlebar with the node type icon and remove button.
func _set_node_titlebar():
	var node_titlebar = get_titlebar_hbox()
	
	if not has_theme_stylebox_override("titlebar"):
		var titlebar_stylebox = get_theme_stylebox("titlebar").duplicate()
		titlebar_stylebox.bg_color = node_color
		add_theme_stylebox_override("titlebar", titlebar_stylebox)
	
	if not has_theme_stylebox_override("titlebar_selected"):
		var titlebar_selected_stylebox = get_theme_stylebox("titlebar_selected").duplicate()
		titlebar_selected_stylebox.bg_color = node_color
		add_theme_stylebox_override("titlebar_selected", titlebar_selected_stylebox)
	
	# Add node type icon
	var icon_button = TextureButton.new()
	icon_button.texture_normal = node_icon
	icon_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	node_titlebar.add_child(icon_button)
	node_titlebar.move_child(icon_button, 0)
	
	# Add remove node button
	var remove_button = TextureButton.new()
	remove_button.texture_normal = get_theme_icon('Remove', 'EditorIcons')
	remove_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	remove_button.pressed.connect(graph_editor.delete_node.bind(self))
	node_titlebar.add_child(remove_button)


func _on_resized() -> void:
	size.y = 0 # Keep vertical size on resize
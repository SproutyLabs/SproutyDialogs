@tool
class_name BaseNode
extends GraphNode

## -----------------------------------------------------------------------------
## Base Node to create custom nodes for the Graph Dialog System.
##
## It provides the basic structure to create custom nodes for the graph editor.
## -----------------------------------------------------------------------------

## Node color to display on the node titlebar.
@export_color_no_alpha var node_color: Color
## Icon to display on the node titlebar.
@export var node_icon: Texture2D

## Graph Editor where the node is placed.
@onready var graph_editor: GraphEdit = get_parent()
## Start node of the dialog tree.
@onready var start_node: BaseNode = null
## Array to store the output nodes connections.
@onready var to_node: Array = []

## Node type name.
var node_type: String = ""
## Index of the node in the graph editor.
var node_index: int = 0

## Icon of the remove button.
var _remove_icon: Texture2D = preload("res://addons/graph_dialog_system/icons/Remove.svg")


func _ready():
	# Set node type and connect nodes loaded signal
	node_type = name.to_snake_case().split("_node_")[0] + "_node"
	graph_editor.connect("nodes_loaded", _load_output_connections)
	set_node_titlebar()


## Get the node data as a dictionary.
func get_data() -> Dictionary:
	# Abstract method to implement in child nodes
	return {}


## Set the node data from a dictionary.
func set_data(dict: Dictionary) -> void:
	# Abstract method to implement in child nodes
	pass


## Load the output connections of the node.
func _load_output_connections() -> void:
	for output_node in to_node:
		if output_node == "END":
			continue
		graph_editor.connect_node(name, to_node.find(output_node), output_node, 0)
		graph_editor.get_node(output_node).start_node = start_node


## Get the start node id of the dialog tree.
func get_start_id() -> String:
	if start_node == null: return ""
	else: return start_node.get_start_id()


## Set the node titlebar with the node type icon and remove button.
func set_node_titlebar():
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
	remove_button.texture_normal = _remove_icon
	remove_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	remove_button.connect("pressed", graph_editor.delete_node.bind(self))
	node_titlebar.add_child(remove_button)


func _on_resized() -> void:
	size.y = 0 # Keep vertical size on resize
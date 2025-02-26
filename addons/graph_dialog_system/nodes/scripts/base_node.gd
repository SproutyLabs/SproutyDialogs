@tool
class_name BaseNode
extends GraphNode

@export_color_no_alpha var node_color : Color
@export var node_icon : Texture2D

@onready var graph_editor : GraphEdit = get_parent()
@onready var start_node : BaseNode = null
@onready var to_node : Array = []

var node_type : String = ""
var node_index : int = 0

var _remove_icon : Texture2D = preload("res://addons/graph_dialog_system/icons/Remove.svg")

func _ready():
	node_type = name.to_snake_case().split("_node_")[0] + "_node"
	graph_editor.connect("nodes_loaded", _load_output_connections)
	set_node_titlebar()

func get_data() -> Dictionary:
	# Abstract method to get node data on dict
	return {}

func set_data(dict: Dictionary) -> void:
	# Abstract method to set node data from dict
	pass

func _on_resized() -> void:
	size.y = 0 # Keep vertical size on resize

func _load_output_connections() -> void:
	# Load connection to output nodes
	for output_node in to_node:
		if output_node == "END":
			continue
		graph_editor.connect_node(name, to_node.find(output_node), output_node, 0)
		graph_editor.get_node(output_node).start_node = start_node

func get_start_id() -> String:
	# Get dialog id from start node
	if start_node == null: return ""
	else: return start_node.get_start_id()

func set_node_titlebar():
	# Set titlebar color and button icons
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

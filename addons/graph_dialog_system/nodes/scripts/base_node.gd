@tool
class_name BaseNode
extends GraphNode

@export_color_no_alpha var node_color : Color
@export var node_icon : Texture2D

@onready var to_node : Array[String] = []
@onready var node_dialog_id : String = ""
@onready var start_node : BaseNode = null

var _remove_icon : Texture2D = preload("res://addons/graph_dialog_system/icons/Remove.svg")

func _ready():
	get_parent().connect("nodes_loaded", _load_output_connections)
	set_node_titlebar()

func _on_resized() -> void:
	size.y = 0 # Keep vertical size on resize

func _load_output_connections() -> void:
	# Load connection to output nodes
	for output_node in to_node:
		get_parent().connect_node(name, to_node.find(output_node), to_node, 0)
		get_parent().get_node(output_node).node_dialog_id = node_dialog_id

func get_data() -> Dictionary:
	# Abstract method to get node data on dict
	return {}

func set_data(dict: Dictionary) -> void:
	# Abstract method to set node data from dict
	pass

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
	remove_button.connect("pressed", get_parent().delete_node.bind(self))
	node_titlebar.add_child(remove_button)

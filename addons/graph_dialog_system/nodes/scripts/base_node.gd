@tool
class_name BaseNode
extends GraphNode

@export_color_no_alpha var node_color : Color
@export var node_icon : Texture2D

var remove_icon : Texture2D =  preload("res://addons/graph_dialog_system/icons/Remove.svg")

func _ready():
	set_node_titlebar()

func _on_resized() -> void:
	size.y = 0 # Keep vertical size on resize

func set_node_titlebar():
	# Set titlebar color and button icons
	var node_titlebar = get_titlebar_hbox()
	
	var titlebar_stylebox = get_theme_stylebox("titlebar").duplicate()
	titlebar_stylebox.bg_color = node_color
	add_theme_stylebox_override("titlebar", titlebar_stylebox)
	
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
	remove_button.texture_normal = remove_icon
	remove_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	remove_button.connect("pressed", get_parent().delete_node.bind(self))
	node_titlebar.add_child(remove_button)

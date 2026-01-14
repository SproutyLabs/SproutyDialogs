@tool
@abstract
class_name SproutyDialogsBaseNode
extends GraphNode

# -----------------------------------------------------------------------------
# Sprouty Dialogs Base Node
# -----------------------------------------------------------------------------
## Abstract class for graph nodes from Sprouty Dialogs plugin.
##
## It handles the node color and icon for the titlebar.
## It also provides methods to get and set the node data that should be 
## overridden in each child node class.
##
## [br][br]You should inherit from this class to create your own dialog nodes.
# -----------------------------------------------------------------------------

## Emitted when the node is modified.
signal modified(modified: bool)

## Node color to display on the node titlebar.
@export_color_no_alpha var node_color: Color

## Icon to display on the node titlebar.
@export var node_icon: Texture2D

## Name of the start node in the dialog tree where the node belongs.
## Used to find the start node in the graph editor on load.
var start_node_name: String = ""
## Start node of the dialog tree where the node belongs.
var start_node: SproutyDialogsBaseNode = null
## Array to store the output nodes connections.
var to_node: Array = []

## Node type name.
var node_type: String = ""
## Index of the node in the graph editor.
var node_index: int = 0

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


## Returns the node data as a dictionary.
## This method should be overridden in each node.
@abstract func get_data() -> Dictionary


## Set the node data from a dictionary.
## This method should be overridden in each node.
@abstract func set_data(dict: Dictionary) -> void


func _ready():
	resized.connect(_on_resized)
	_set_node_titlebar()


## Returns the start node id of the dialog tree.
func get_start_id() -> String:
	if start_node == null: return ""
	else: return start_node.get_start_id()


## Returns an array with the node's output connections
func get_output_connections() -> Array:
	var connections: Array = get_parent().get_node_connections(name)
	var output_connections: Array = []

	# Add a item for each active slot
	for index in get_child_count():
		if is_slot_enabled_right(index):
			output_connections.append("END")
	
	for connection in connections: # Set the connected nodes
		output_connections.set(connection["from_port"], connection["to_node"].to_snake_case())
	
	return output_connections


## Set the node titlebar with the node type icon and remove button.
func _set_node_titlebar():
	var node_titlebar = get_titlebar_hbox()
	_set_titlebar_color()
	
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
	if get_parent() is EditorSproutyDialogsGraphEditor:
		remove_button.pressed.connect(get_parent().delete_node.bind(self))
	node_titlebar.add_child(remove_button)


## Set the node titlebar color
func _set_titlebar_color() -> void:
	var titlebar_stylebox = get_theme_stylebox("titlebar").duplicate()
	titlebar_stylebox.bg_color = node_color
	add_theme_stylebox_override("titlebar", titlebar_stylebox)
	
	var titlebar_selected_stylebox = get_theme_stylebox("titlebar_selected").duplicate()
	titlebar_selected_stylebox.bg_color = node_color
	add_theme_stylebox_override("titlebar_selected", titlebar_selected_stylebox)


func _on_resized() -> void:
	size.y = 0 # Keep vertical size on resize
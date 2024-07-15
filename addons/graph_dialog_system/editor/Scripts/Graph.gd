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
	new_node.name = "node_" + str(get_child_count())
	new_node.title += ' #' + new_node.name.split('_')[1]
	new_node.position_offset = cursor_pos
	new_node.selected = true
	add_child(new_node, true)
#endregion

@tool
extends HSplitContainer

## =============================================================================
## Workspace controller
##
## This script handles the workspace, the main UI of the editor. It contains the
## graph editor, the text editor, and the start panel.
## =============================================================================

## Editor main reference
@export var _editor_main: Control
## File manager reference
@export var _file_manager: Container

## Graph editor reference
@onready var _graph_editor: Panel = $GraphEditor
## Empty panel reference
@onready var _empty_panel: Panel = $EmptyPanel
## Text editor reference
@onready var text_editor: Panel = $TextEditor


func _ready() -> void:
	show_start_panel()


#region === Graph Editor =======================================================

## Get the current graph on editor
func get_current_graph() -> GraphEdit:
	if _graph_editor.get_child_count() > 0:
		return _graph_editor.get_child(0)
	else: return null


## Switch the current graph on editor
func switch_current_graph(new_graph: GraphEdit) -> void:
	# Remove old graph and switch to the new one
	if _graph_editor.get_child_count() > 0:
		_graph_editor.remove_child(_graph_editor.get_child(0))
	_graph_editor.add_child(new_graph)

#endregion

#region === UI Panel Handling ==================================================

## Show the start panel instead of graph editor
func show_start_panel() -> void:
	if _file_manager:
		_file_manager.hide_csv_container()
	_graph_editor.visible = false
	text_editor.visible = false
	_empty_panel.visible = true


## Show the graph editor
func show_graph_editor() -> void:
	if _file_manager:
		_file_manager.show_csv_container()
	_graph_editor.visible = true
	_empty_panel.visible = false
#endregion

#region === Start panel Handling ===============================================

## Show dialog to open a dialog file
func _on_open_dialog_file_pressed() -> void:
	_file_manager.select_file_to_open()

## Show dialog to create a new dialog file
func _on_new_dialog_file_pressed() -> void:
	_file_manager.select_new_dialog_file()
#endregion

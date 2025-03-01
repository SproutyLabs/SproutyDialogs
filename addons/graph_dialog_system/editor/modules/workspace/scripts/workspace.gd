@tool
extends HSplitContainer

## =============================================================================
## Workspace controller
##
## This script handles the workspace, the main UI of the editor. It contains the
## graph editor, the text editor, and the start panel.
## =============================================================================

## Editor main reference
@export var editor_main: Control
## File manager reference
@export var file_manager: VSplitContainer

## Graph editor reference
@onready var graph_editor: Panel = $GraphEditor
## Start panel reference
@onready var start_panel: Panel = $StartPanel
## Text editor reference
@onready var text_editor: Panel = $TextEditor

func _ready():
	show_start_panel()

#region === Graph Editor =======================================================

## Get the current graph on editor
func get_current_graph() -> GraphEdit:
	if graph_editor.get_child_count() > 0:
		return graph_editor.get_child(0)
	else: return null


## Switch the current graph on editor
func switch_current_graph(new_graph: GraphEdit) -> void:
	if graph_editor.get_child_count() > 0:
		# Remove old graph and switch to the new one
		graph_editor.remove_child(graph_editor.get_child(0))
		graph_editor.add_child(new_graph)
	else:
		graph_editor.add_child(new_graph)
#endregion

#region === UI Panel Handling ==================================================

## Show the start panel instead of graph editor
func show_start_panel() -> void:
	if file_manager:
		file_manager.hide_csv_container()
	graph_editor.visible = false
	text_editor.visible = false
	start_panel.visible = true


## Show the text editor
func show_graph_editor() -> void:
	if file_manager:
		file_manager.show_csv_container()
	graph_editor.visible = true
	start_panel.visible = false
#endregion

#region === Start panel Handling ===============================================

## Show dialog to open a dialog file
func _on_open_dialog_file_pressed() -> void:
	file_manager.select_file_to_open()

## Show dialog to create a new dialog file
func _on_create_dialog_file_pressed() -> void:
	file_manager.select_new_dialog_file()
#endregion

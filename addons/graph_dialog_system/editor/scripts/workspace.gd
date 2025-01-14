@tool
extends HSplitContainer

@export var editor_main : Control
@export var file_manager : VSplitContainer

@onready var graph_editor : Panel = $GraphEditor
@onready var start_panel : Panel = $StartPanel
@onready var text_editor : Panel = $TextEditor
@onready var csv_file_panel : Panel = $CSVFilePanel

@onready var open_csv_dialog : FileDialog = $CSVFilePanel/OpenCSVDialog
@onready var new_csv_dialog : FileDialog = $CSVFilePanel/NewCSVDialog

func _ready():
	show_start_panel()

#region --- Graph Editor ---
func get_current_graph() -> GraphEdit:
	# Return the current graph on editor
	if graph_editor.get_child_count() > 0:
		return graph_editor.get_child(0)
	else: return null

func switch_current_graph(new_graph : GraphEdit) -> void:
	# Switch the current graph on editor
	if graph_editor.get_child_count() > 0:
		# Remove old graph and switch to the new one
		graph_editor.remove_child(graph_editor.get_child(0))
		graph_editor.add_child(new_graph)
	else: 
		graph_editor.add_child(new_graph)
#endregion

#region --- UI Panel Handling ---
func show_start_panel() -> void:
	# Show start panel instead of graph editor
	file_manager.csv_file_field.get_parent().visible = false
	csv_file_panel.visible = false
	graph_editor.visible = false
	text_editor.visible = false
	start_panel.visible = true

func show_graph_editor() -> void:
	# Show the graph editor
	file_manager.csv_file_field.get_parent().visible = true
	csv_file_panel.visible = false
	graph_editor.visible = true
	start_panel.visible = false

func show_csv_file_panel() -> void:
	# Show the csv file selector panel
	file_manager.csv_file_field.get_parent().visible = false
	csv_file_panel.visible = true
	graph_editor.visible = false
	text_editor.visible = false
	start_panel.visible = false
#endregion

#region --- File Selection ---
func _on_open_csv_file_pressed() -> void:
	open_csv_dialog.popup_centered()

func _on_create_csv_file_pressed() -> void:
	new_csv_dialog.popup_centered()

func _on_open_csv_dialog_file_selected(path : String) -> void:
	file_manager.set_dialog_csv_file(path)
	show_graph_editor()

func _on_new_csv_dialog_file_selected(path : String) -> void:
	file_manager.new_csv_file(path)
	show_graph_editor()

func _on_open_dialog_file_pressed() -> void:
	# Open a dialog file to load
	file_manager.open_file_panel.popup_centered()

func _on_create_dialog_file_pressed() -> void:
	# Create new dialog file
	file_manager.new_dialog_panel.popup_centered()
#endregion

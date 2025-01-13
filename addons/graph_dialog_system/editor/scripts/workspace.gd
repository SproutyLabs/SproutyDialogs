@tool
extends HSplitContainer

@onready var graph_editor : Panel = $GraphEditor
@onready var start_panel : Panel = $StartPanel
@onready var text_editor : Panel = $TextEditor
@onready var csv_file_panel : Panel = $CSVFilePanel

@onready var open_csv_dialog : FileDialog = $CSVFilePanel/OpenCSVDialog
@onready var new_csv_dialog : FileDialog = $CSVFilePanel/NewCSVDialog

func _ready():
	show_start_panel()

func get_current_graph() -> GraphEdit:
	# Return the current graph on editor
	return graph_editor.get_child(0)

func switch_current_graph(new_graph : GraphEdit) -> void:
	# Switch the current graph on editor
	print("switching graph")
	for child in graph_editor.get_children():
		print(child.name)
	graph_editor.remove_child(graph_editor.get_child(0))
	graph_editor.add_child(new_graph)

func show_start_panel() -> void:
	# Show start panel instead of graph editor
	csv_file_panel.visible = false
	graph_editor.visible = false
	text_editor.visible = false
	start_panel.visible = true

func show_graph_editor() -> void:
	# Show the graph editor
	csv_file_panel.visible = false
	graph_editor.visible = true
	start_panel.visible = false

func show_csv_file_panel() -> void:
	# Show the csv file selector panel
	csv_file_panel.visible = true
	graph_editor.visible = false
	text_editor.visible = false
	start_panel.visible = false

func _on_open_csv_file_pressed():
	open_csv_dialog.popup_centered()

func _on_create_csv_file_pressed():
	new_csv_dialog.popup_centered()

func _on_open_csv_dialog_file_selected(path):
	show_graph_editor()
	pass # Replace with function body.

func _on_new_csv_dialog_file_selected(path):
	show_graph_editor()
	pass # Replace with function body.

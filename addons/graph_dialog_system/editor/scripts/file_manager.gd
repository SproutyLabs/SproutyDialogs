@tool
extends VSplitContainer

@export var file_filters : PackedStringArray

@onready var graph_editor : GraphEdit = get_parent().get_node("%Workspace/Graph")
@onready var open_file_dialog : FileDialog

var save_path : String = "res://addons/graph_dialog_system/example.json"

func _ready():
	open_file_dialog = find_parent("Main").get_node("OpenFileDialog")
	open_file_dialog.connect("file_selected", _on_file_selected)

func _on_file_selected(path : String) -> void:
	load_dialog_file(path)

func load_dialog_file(path : String) -> void:
	# Load dialog data from JSON file
	if JSONFileManager.file_exists(path):
		var data = JSONFileManager.load_file(path)
		if not graph_editor.is_graph_empty():
			# TODO: Ask for save current editing file
			graph_editor.clear_graph()
		graph_editor.load_nodes_data(data)
	else:
		printerr("[Graph Dialogs] File " + path + "does not exist.")

func save_dialog_file() -> void:
	# Save dialog data on JSON file
	var data = {
		"csv_file_path" : "path/to/csv",
		"nodes_data" : {}
	}
	data["nodes_data"] = get_parent().get_node("%Workspace/Graph").get_nodes_data()
	JSONFileManager.save_file(data, save_path)
	print("[Graph Dialogs] Dialog file saved.")

func _on_save_file_pressed():
	save_dialog_file()
	pass # Replace with function body.

func _on_open_file_pressed():
	# Open a file to load
	open_file_dialog.filters = file_filters
	open_file_dialog.visible = true

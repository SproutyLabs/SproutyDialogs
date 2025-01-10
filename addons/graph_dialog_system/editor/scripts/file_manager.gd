@tool
extends VSplitContainer

var save_path = "res://addons/graph_dialog_system/data/example.json"

func _ready():
	pass

func load_dialog_file() -> void:
	# Load dialog data from JSON file
	if JSONFileManager.file_exists(save_path):
		var data = JSONFileManager.load_file(save_path)
		get_parent().get_node("%Workspace/Graph").load_nodes_data(data.dialogs_data)

func save_dialog_file() -> void:
	# Save dialog data on JSON file
	var data = {
		"csv_file_path" : "path/to/csv",
		"dialogs_data" : {}
	}
	data["dialogs_data"] = get_parent().get_node("%Workspace/Graph").get_nodes_data()
	JSONFileManager.save_file(data, save_path)
	print("file saved")

func _on_save_file_pressed():
	save_dialog_file()
	pass # Replace with function body.

func _on_open_file_pressed():
	load_dialog_file()
	pass # Replace with function body.

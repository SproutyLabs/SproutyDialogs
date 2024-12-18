class_name GraphDialogsData
extends Resource

## ------------------------------------------------------------------
## Graph dialogs data handler
## ------------------------------------------------------------------

@export var save_path : String = "res://addons/graph_dialog_system/dialogs"

@export var dialog_data : Dictionary = {}

func save_data() -> void:
	# Save game data on a JSON file
	var data = {}
	GraphDialogsFileManager.save_file(data, save_path)

func load_data() -> void:
	# Load settings from a JSON file
	if FileAccess.file_exists(save_path):
		var data = GraphDialogsFileManager.load_file(save_path)
		
		# General data
		#player_position.x = data.game_data.player_position.x

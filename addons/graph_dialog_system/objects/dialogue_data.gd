class_name DialogueData
extends Resource

## ------------------------------------------------------------------
## Graph dialogs data handler
## ------------------------------------------------------------------

@export var save_path : String

@export var dialog_data : Dictionary = {}

func save_data() -> void:
	# Save game data on a JSON file
	var data = {}
	JSONFileManager.save_file(data, save_path)

func load_data() -> void:
	# Load settings from a JSON file
	if JSONFileManager.file_exists(save_path):
		var data = JSONFileManager.load_file(save_path)
		
		# General data
		#player_position.x = data.game_data.player_position.x

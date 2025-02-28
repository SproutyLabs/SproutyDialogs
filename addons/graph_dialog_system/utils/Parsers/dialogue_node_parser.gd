class_name DialogueNodeParser
extends NodeParser

## ------------------------------------------------------------------
## Parser for process a dialogue node
## ------------------------------------------------------------------

signal dialogue_processed(character : String, dialog : String, next_node : String)

func process_node(node_data: Dictionary) -> void:
	# Processes the dialogue node
	var character = node_data["char_key"]
	var dialog = tr(node_data["dialog_key"])
	
	dialogue_processed.emit(character, dialog, node_data["to_node"][0])

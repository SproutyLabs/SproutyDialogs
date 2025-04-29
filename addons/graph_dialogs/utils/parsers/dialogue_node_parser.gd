class_name DialogueNodeParser
extends NodeParser

## -----------------------------------------------------------------------------
## Parser for process a dialogue node
## -----------------------------------------------------------------------------

## Signal to indicate that the dialogue node was processed
signal dialogue_processed(character: String, dialog: String, next_node: String)

## Process a dialogue node to display the dialog
func process_node(node_data: Dictionary) -> void:
	var character = node_data["char_key"]
	var dialog = tr(node_data["dialog_key"])
	
	dialogue_processed.emit(character, dialog, node_data["to_node"][0])

@tool
class_name DialogParser
extends Node

## Emitted when the node is processed and is ready to continue to the next node.
signal continue_to_node(to_node: String)
## Emitted when the dialogue node was processed.
signal dialogue_processed(
	character: String,
	portrait: String,
	dialog: String,
	next_node: String
)

## Node processors reference dictionary.
var node_processors: Dictionary = {
	"start_node": process_start,
	"dialogue_node": process_dialogue,
	"condition_node": process_condition,
	"options_node": process_options,
	"set_variable_node": process_set_variable,
	"signal_node": process_signal,
	"wait_node": process_wait
}


func process_start(node_data: Dictionary) -> void:
	print("[Graph Dialogs] Processing start node...")
	continue_to_node.emit(node_data.to_node[0])


func process_dialogue(node_data: Dictionary) -> void:
	print("[Graph Dialogs] Processing dialogue node...")
	var character = node_data["character"]
	var portrait = node_data["portrait"]

	var dialog = _get_translated_dialog(node_data["dialog_key"])
	dialog = _parse_variables(dialog) # Parse variables in the dialog text
	dialogue_processed.emit(character, portrait, dialog, node_data["to_node"][0])


#region === Dialog processing ==================================================

## Returns the translated dialog text
func _get_translated_dialog(key: String) -> String:
	# If translation is enabled and using CSV, use the translation server
	if GraphDialogsSettings.get_setting("enable_translations") \
			and GraphDialogsSettings.get_setting("use_csv"):
		return tr(key)
	else: # Otherwise, get the dialog from the dialog resource
		var locale = TranslationServer.get_locale()
		return get_parent().dialog_data.dialogs[key][locale]


# Replaces all {} variables with their corresponding values in the dialog.
func _parse_variables(value: String) -> String:
	# Get the list of all the variables in the string denoted in {}.
	var regex := RegEx.new()
	regex.compile('{([^{}]+)}')
	var results = regex.search_all(value)
	results = results.map(func(val): return val.get_string(1))
	if not results.is_empty():
		print("[Graph Dialogs] Variables in dialog: ", results)

	# TODO: Implement variable parsing
	
	return value

#endregion


func process_condition(node_data: Dictionary) -> void:
	# TODO: Process the node
	print("[Graph Dialogs] Processing condition node...")
	continue_to_node.emit(node_data.to_node[0])


func process_options(node_data: Dictionary) -> void:
	# TODO: Process the node
	print("[Graph Dialogs] Processing options node...")
	continue_to_node.emit(node_data.to_node[0])


func process_set_variable(node_data: Dictionary) -> void:
	# TODO: Process the node
	print("[Graph Dialogs] Processing set variable node...")
	continue_to_node.emit(node_data.to_node[0])


func process_signal(node_data: Dictionary) -> void:
	# TODO: Process the node
	print("[Graph Dialogs] Processing signal node...")
	continue_to_node.emit(node_data.to_node[0])


func process_wait(node_data: Dictionary) -> void:
	# TODO: Process the node
	print("[Graph Dialogs] Processing wait node...")
	continue_to_node.emit(node_data.to_node[0])

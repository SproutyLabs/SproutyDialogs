class_name DialogParser
extends Node

# -----------------------------------------------------------------------------
## Dialog Parser
##
## This class is responsible for processing the dialog nodes from the graph.
## The parsers can be access by the [param node_processors] dictionary, that is
## used by the [DialogPlayer] to process the nodes by their type.
# -----------------------------------------------------------------------------

## Emitted when the node is processed and is ready to continue to the next node.
signal continue_to_node(to_node: String)
## Emitted when the dialogue node was processed.
signal dialogue_processed(
	character_name: String,
	translated_name: String,
	portrait: String,
	dialog: String,
	next_node: String
)

## Node processors reference dictionary.
var node_processors: Dictionary = {
	"start_node": _process_start,
	"dialogue_node": _process_dialogue,
	"condition_node": _process_condition,
	"options_node": _process_options,
	"set_variable_node": _process_set_variable,
	"signal_node": _process_signal,
	"wait_node": _process_wait
}


func _process_start(node_data: Dictionary) -> void:
	print("[Graph Dialogs] Processing start node...")
	continue_to_node.emit(node_data.to_node[0])


func _process_dialogue(node_data: Dictionary) -> void:
	print("[Graph Dialogs] Processing dialogue node...")
	var dialog = _get_translated_dialog(node_data["dialog_key"])
	dialogue_processed.emit(
		node_data["character"],
		_get_translated_character_name(node_data["character"]),
		node_data["portrait"],
		_parse_variables(dialog),
		node_data["to_node"][0]
	)


#region === Dialog processing ==================================================

## Returns the translated dialog text
func _get_translated_dialog(key: String) -> String:
	# If translation is enabled and using CSV, use the translation server
	if GraphDialogsSettings.get_setting("enable_translations") \
			and GraphDialogsSettings.get_setting("use_csv"):
		return tr(key)
	else: # Otherwise, get the dialog from the dialog resource
		var locale = TranslationServer.get_locale()
		return get_parent().get_dialog_data().dialogs[key][locale]


## Returns the translated character name
func _get_translated_character_name(character: String) -> String:
	# If translation is enabled and using CSV, use the translation server
	if GraphDialogsSettings.get_setting("enable_translations") \
			and GraphDialogsSettings.get_setting("translate_character_names"):
		if GraphDialogsSettings.get_setting("use_csv_for_character_names"):
			return tr(character)
		else: # Otherwise, get the dialog from the dialog resource
			var locale = TranslationServer.get_locale()
			return get_parent().get_character_data(character).display_name[locale]
	return character # If no translation is enabled, return the original name


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


func _process_condition(node_data: Dictionary) -> void:
	# TODO: Process the node
	print("[Graph Dialogs] Processing condition node...")
	continue_to_node.emit(node_data.to_node[0])


func _process_options(node_data: Dictionary) -> void:
	# TODO: Process the node
	print("[Graph Dialogs] Processing options node...")
	continue_to_node.emit(node_data.to_node[0])


func _process_set_variable(node_data: Dictionary) -> void:
	# TODO: Process the node
	print("[Graph Dialogs] Processing set variable node...")
	continue_to_node.emit(node_data.to_node[0])


func _process_signal(node_data: Dictionary) -> void:
	# TODO: Process the node
	print("[Graph Dialogs] Processing signal node...")
	continue_to_node.emit(node_data.to_node[0])


func _process_wait(node_data: Dictionary) -> void:
	# TODO: Process the node
	print("[Graph Dialogs] Processing wait node...")
	continue_to_node.emit(node_data.to_node[0])

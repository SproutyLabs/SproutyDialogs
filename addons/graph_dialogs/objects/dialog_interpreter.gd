class_name DialogInterpreter
extends Node

# -----------------------------------------------------------------------------
## Dialog Interpreter
##
## This class is responsible for processing the dialog nodes from the graph.
## The processors can be access by the [param node_processors] dictionary, that
## is used by the [DialogPlayer] to process the nodes by their type.
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
## Emitted when the options node was processed.
signal options_processed(options: Array, next_nodes: Array)
## Emitted when the signal node was processed.
signal signal_processed(signal_argument: String, next_node: String)

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
## # If true, will print debug messages to the console
var print_debug: bool = true


#region === Dialogs translation ================================================

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

#endregion


func _process_start(node_data: Dictionary) -> void:
	if print_debug: print("[Graph Dialogs] Processing start node...")
	continue_to_node.emit(node_data.to_node[0])


func _process_dialogue(node_data: Dictionary) -> void:
	if print_debug: print("[Graph Dialogs] Processing dialogue node...")
	# Get the translated dialog and character name to display
	var dialog = _get_translated_dialog(node_data["dialog_key"])
	dialog = GraphDialogsVariableManager.parse_variables(dialog)
	var display_name = _get_translated_character_name(node_data["character"])

	dialogue_processed.emit(node_data["character"], display_name,
			node_data["portrait"], dialog, node_data["to_node"][0])


func _process_condition(node_data: Dictionary) -> void:
	if print_debug: print("[Graph Dialogs] Processing condition node...")
	var comparison_result = GraphDialogsVariableManager.get_comparison_result(
		node_data.first_type, # First variable type
		node_data.first_value, # First variable value
		node_data.second_type, # Second variable type
		node_data.second_value, # Second variable value
		node_data.operator # Comparison operator
	)
	if comparison_result: # If is true, continue to the first connection
		continue_to_node.emit(node_data.to_node[0])
	else: # If is false, continue to the second connection
		continue_to_node.emit(node_data.to_node[1])


func _process_options(node_data: Dictionary) -> void:
	if print_debug: print("[Graph Dialogs] Processing options node...")
	options_processed.emit(node_data.options_keys.map(
		func(key): # Return the translated and parsed options
			return GraphDialogsVariableManager.parse_variables(
				_get_translated_dialog(key))
	), node_data.to_node)


func _process_set_variable(node_data: Dictionary) -> void:
	if print_debug: print("[Graph Dialogs] Processing set variable node...")
	var variable = GraphDialogsVariableManager.get_variable(node_data.var_name)
	if not variable: # If the variable is not found, print an error and return
		printerr("[Graph Dialogs] Cannot set variable '" + node_data.var_name + "' not found. " +
			"Please check if the variable exists in the Variables Manager or in the autoloads.")
		return
	var assignment_result = GraphDialogsVariableManager.get_assignment_result(
		node_data.var_type, # Variable type
		node_data.operator, # Assignment operator
		variable.value, # Current variable value
		node_data.new_value # New value to assign
	)
	GraphDialogsVariableManager.set_variable(node_data.var_name, assignment_result)
	continue_to_node.emit(node_data.to_node[0])


func _process_signal(node_data: Dictionary) -> void:
	if print_debug: print("[Graph Dialogs] Processing signal node...")
	signal_processed.emit(node_data.signal_argument, node_data.to_node[0])


func _process_wait(node_data: Dictionary) -> void:
	if print_debug: print("[Graph Dialogs] Processing wait node...")
	await get_tree().create_timer(node_data.time).timeout
	continue_to_node.emit(node_data.to_node[0])

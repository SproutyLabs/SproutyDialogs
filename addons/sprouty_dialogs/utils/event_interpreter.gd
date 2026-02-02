class_name SproutyDialogsEventInterpreter
extends Node

# -----------------------------------------------------------------------------
# Sprouty Dialogs Event Interpreter
# -----------------------------------------------------------------------------
## Node that process the event nodes of a dialog tree from the Sprouty Dialogs plugin.
##
## This node is used by the [DialogPlayer] to process the nodes of a dialog tree.
## You should not need to use this node directly.[br]
##
## The processors can be access by the [param node_processors] dictionary, that
## is used by the [DialogPlayer] to process the nodes by their type.
# -----------------------------------------------------------------------------

## Emitted when a node is processed and is ready to continue to the next node.
signal continue_to_node(to_node: String)
## Emitted when a dialogue node was processed.
signal dialogue_processed(
	character_name: String,
	translated_name: String,
	portrait: String,
	dialog: String,
	next_node: String
)
## Emitted when a options node was processed.
signal options_processed(options: Array, next_nodes: Array)
## Emitted when a signal node was processed.
signal signal_processed(signal_argument: String, next_node: String)

## Node processors reference dictionary.
## This dictionary maps the node type to its processing method.
## You can call the processors from this dictionary.
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

# Sprouty dialogs manager reference
@onready var _sprouty_dialogs: SproutyDialogsManager = get_node("/root/SproutyDialogs")


func _process_start(node_data: Dictionary) -> void:
	if print_debug: print("[Sprouty Dialogs] Processing start node...")
	continue_to_node.emit(node_data.to_node[0])


func _process_dialogue(node_data: Dictionary) -> void:
	if print_debug: print("[Sprouty Dialogs] Processing dialogue node...")

	# Get the translated dialog and parse variables
	var dialog = SproutyDialogsTranslationManager.get_translated_dialog(
			node_data["dialog_key"], get_parent().get_dialog_data())
	dialog = _sprouty_dialogs.Variables.parse_variables(dialog)

	# Get the translated character name
	var character_data = get_parent().get_character_data(node_data["character"])
	var display_name = ""
	var portrait = node_data["portrait"]

	if character_data:
		display_name = SproutyDialogsTranslationManager.get_translated_character_name(
				node_data["character"], character_data)
		display_name = _sprouty_dialogs.Variables.parse_variables(display_name)

		if portrait.is_empty(): # Use default portrait
			portrait = character_data.default_portrait

	dialogue_processed.emit(node_data["character"], display_name,
			portrait, dialog, node_data["to_node"][0])


func _process_condition(node_data: Dictionary) -> void:
	if print_debug: print("[Sprouty Dialogs] Processing condition node...")
	var comparison_result = _sprouty_dialogs.Variables.get_comparison_result(
		node_data.first_var, # First variable data
		node_data.second_var, # Second variable data
		node_data.operator # Comparison operator
	)
	if comparison_result: # If is true, continue to the first connection
		continue_to_node.emit(node_data.to_node[0])
	else: # If is false, continue to the second connection
		continue_to_node.emit(node_data.to_node[1])


func _process_options(node_data: Dictionary) -> void:
	if print_debug: print("[Sprouty Dialogs] Processing options node...")
	options_processed.emit(node_data.options_keys.map(
		func(key): # Return the translated and parsed options
			return _sprouty_dialogs.Variables.parse_variables(
				SproutyDialogsTranslationManager.get_translated_dialog(
					key, get_parent().get_dialog_data()))
	), node_data.to_node)


func _process_set_variable(node_data: Dictionary) -> void:
	if print_debug: print("[Sprouty Dialogs] Processing set variable node...")
	var variable = _sprouty_dialogs.Variables.get_variable(node_data.var_name)
	if variable == null: # If the variable is not found, print an error and return
		printerr("[Sprouty Dialogs] Cannot set variable '" + node_data.var_name + "' not found. " +
			"Please check if the variable exists in the Variables Manager or in the autoloads.")
		return
	var assignment_result = _sprouty_dialogs.Variables.get_assignment_result(
		node_data.var_type, # Variable type
		node_data.operator, # Assignment operator
		variable, # Current variable value
		node_data.new_value # New value to assign
	)
	_sprouty_dialogs.Variables.set_variable(node_data.var_name, assignment_result)
	continue_to_node.emit(node_data.to_node[0])


func _process_signal(node_data: Dictionary) -> void:
	if print_debug: print("[Sprouty Dialogs] Processing signal node...")
	signal_processed.emit(node_data.signal_argument, node_data.to_node[0])


func _process_wait(node_data: Dictionary) -> void:
	if print_debug: print("[Sprouty Dialogs] Processing wait node...")
	await get_tree().create_timer(node_data.wait_time).timeout
	continue_to_node.emit(node_data.to_node[0])

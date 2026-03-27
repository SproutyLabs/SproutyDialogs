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
	dialog_data: Dictionary,
	next_node: String
)
## Emitted when a options node was processed.
signal options_processed(options: Array, next_nodes: Array, option_keys: Array, disabled_flags: Array)
## Emitted when a signal node was processed.
signal signal_processed(signal_id: String, args: Array, next_node: String)
## Emitted when a wait node was processed
signal wait_processed(wait_time: float, next_node: String)
## Emitted when a jump node was processed.
signal jump_to_node(start_node: String, start_id: String, return_node: String)

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
	"wait_node": _process_wait,
	"call_method_node": _process_call_method,
	"jump_to_node": _process_jump_to
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
	var parser: SproutyDialogsTagsParser = SproutyDialogsTagsParser.new(dialog, _sprouty_dialogs.Variables)
#	dialog = parser.bbcode_text

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
			portrait, parser.dialog_data, node_data["to_node"][0])


func _process_options(node_data: Dictionary) -> void:
	if print_debug: print("[Sprouty Dialogs] Processing options node...")

	var filtered_options: Array = []
	var filtered_next_nodes: Array = []
	var filtered_option_keys: Array = []
	var disabled_flags: Array = []
	var options_conditions: Array = node_data.get("options_conditions", [])

	for i in range(node_data.options_keys.size()):
		var key = node_data.options_keys[i]
		var option_text = _sprouty_dialogs.Variables.parse_variables(
			SproutyDialogsTranslationManager.get_translated_dialog(
				key, get_parent().get_dialog_data()
			)
		)

		var condition_data: Dictionary = {}
		if i < options_conditions.size() and options_conditions[i] is Dictionary:
			condition_data = options_conditions[i].duplicate(true)

		var show_option := true
		var disable_option := false

		if not condition_data.is_empty() and condition_data.get("enabled", false):
			var result = _sprouty_dialogs.Variables.get_comparison_result(
				condition_data.get("first_var", {}),
				condition_data.get("second_var", {}),
				condition_data.get("operator", OP_EQUAL)
			)

			var condition_met = result == true
			var visibility = int(condition_data.get("visibility", 0))

			if not condition_met:
				if visibility == 0:
					show_option = false
				else:
					show_option = true
					disable_option = true

		if show_option:
			filtered_options.append(option_text)
			filtered_next_nodes.append(node_data.to_node[i])
			filtered_option_keys.append(key)
			disabled_flags.append(disable_option)

	options_processed.emit(
		filtered_options,
		filtered_next_nodes,
		filtered_option_keys,
		disabled_flags
	)


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


func _process_call_method(node_data: Dictionary) -> void:
	if print_debug: print("[Sprouty Dialogs] Processing call method node...")
	if node_data.autoload == "":
		push_warning("[Sprouty Dialogs] Call Method Node #" + str(node_data.node_index)
				+ " does not have an autoload assigned to call a method from it.")
		continue_to_node.emit(node_data.to_node[0])
		return
	
	var autoload = get_tree().root.get_node_or_null(node_data.autoload)
	if autoload:
		if autoload.has_method(node_data.method):
			var args = SproutyDialogsVariableUtils.get_array_from_data(node_data.parameters)
			autoload.callv(node_data.method, args)
		else:
			printerr("[Sprouty Dialogs] Method '" + node_data.method + "' not found in '" +
					node_data.autoload + "' autoload. Check that the method exist.")
	else:
		printerr("[Sprouty Dialogs] Autoload '" + node_data.autoload + "' not found. "
				+ "Check that your script is register as an autoload in Project > Project Settings > Globals.")
	
	continue_to_node.emit(node_data.to_node[0])


func _process_signal(node_data: Dictionary) -> void:
	if print_debug: print("[Sprouty Dialogs] Processing signal node...")

	if node_data.has("signal_argument"): # Old signal node support
		node_data["signal_id"] = node_data["signal_argument"]
		node_data["extra_args"] = []
	
	var args = SproutyDialogsVariableUtils.get_array_from_data(node_data.extra_args)
	get_parent().signal_event.emit(node_data.signal_id, args)
	continue_to_node.emit(node_data.to_node[0])


func _process_wait(node_data: Dictionary) -> void:
	if print_debug: print("[Sprouty Dialogs] Processing wait node...")
	var dialog_box = get_parent().get_current_dialog_box()

	if node_data.get("close_dialog", false): # Close the dialog box
		dialog_box.stop_dialog(true)
	else: # Stop the dialog, but keeps the dialog box visible
		dialog_box.stop_dialog()
		dialog_box.show()
	
	await get_tree().create_timer(node_data.wait_time).timeout
	continue_to_node.emit(node_data.to_node[0])


func _process_jump_to(node_data: Dictionary) -> void:
	if print_debug: print("[Sprouty Dialogs] Processing jump to node...")

	var target_id := str(node_data.get("to_id", "")).to_upper()
	var return_node := "END"
	if node_data.has("to_node") and node_data["to_node"].size() > 0:
		return_node = node_data["to_node"][0]
	var dialog_data: SproutyDialogsDialogueData = get_parent().get_dialog_data()

	if target_id.is_empty() or dialog_data == null:
		push_warning("[Sprouty Dialogs] Jump To Node #" + str(node_data.node_index)
			+ " does not have a valid target ID.")
		continue_to_node.emit(return_node)
		return

	if not dialog_data.graph_data.has(target_id):
		push_warning("[Sprouty Dialogs] Jump To Node #" + str(node_data.node_index)
			+ " cannot find dialog branch '" + target_id + "'.")
		continue_to_node.emit(return_node)
		return

	var start_node := ""
	for node_name in dialog_data.graph_data[target_id].keys():
		if dialog_data.graph_data[target_id][node_name].get("node_type", "") == "start_node":
			start_node = node_name
			break

	if start_node.is_empty():
		push_warning("[Sprouty Dialogs] Jump To Node #" + str(node_data.node_index)
			+ " cannot find a start node for dialog branch '" + target_id + "'.")
		continue_to_node.emit(return_node)
		return

	jump_to_node.emit(start_node, target_id, return_node)

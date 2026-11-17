class_name SproutyDialogsRunner
extends Node

# -----------------------------------------------------------------------------
# Sprouty Dialogs Runner
# -----------------------------------------------------------------------------
## Internal node that executes the dialogue trees from Sprouty Dialogs plugin.
##
## It processes the event nodes, manages the dialogue state and resources, and
## emits execution events for a presentation layer to display the dialogues.
## It does not create or depend on any UI node.[br][br]
##
## Use [DialogPlayer] to play a dialogue with an integrated UI, or
## [DialogController] to handle the dialogue presentation externally.[br]
## You should not need to use this class directly.
# -----------------------------------------------------------------------------

## Emitted when the dialog starts.
signal dialog_started()
## Emitted when a dialogue node is processed and should be displayed.
signal dialogue_requested(
	character_name: String,
	translated_name: String,
	portrait: String,
	dialogue_data: Dictionary
)
## Emitted when an options node is processed and the options should be displayed.
signal options_requested(options: Array, disabled_options: Array)
## Emitted when the dialog is paused.
signal dialog_paused()
## Emitted when the dialog is resumed.
signal dialog_resumed()
## Emitted when the dialog is ended.
signal dialog_ended()

## Emitted when a dialog option is selected.
signal option_selected(option_index: int, option_dialog: Dictionary)
## Emitted when a signal event is emitted.
signal signal_event(signal_id: String, args: Array)

## If [code]true[/code], will print debug messages to the console.
var print_debug: bool = false:
	set(value):
		print_debug = value
		if _dialog_interpreter:
			_dialog_interpreter.print_debug = value

## Optional callback used by wait nodes to retrieve the dialog box that should
## be stopped or hidden. A presentation layer can assign any [Callable] that
## returns a [Node], keeping the runner independent from UI classes.
var dialog_box_getter: Callable = Callable()

## Dialogue data resource being processed.
var _dialog_data: SproutyDialogsDialogueData
## Start ID of the dialogue branch being processed.
var _start_id: String = ""
## Start IDs of the current dialogue data.
var _starts_ids: Array[String] = []

## Dialog interpreter instance to process the dialog nodes.
var _dialog_interpreter: SproutyDialogsEventInterpreter
## Resource manager instance used to load resources for the dialogs.
var _resource_manager: SproutyDialogsResourceManager

## Next nodes options to process when a dialog option is selected.
var _next_options: Array = []
## Current dialog option keys.
var _current_option_keys: Array = []
## Next node to process in the dialog tree after a dialogue node.
var _next_node: String = ""
## Next dialog to process if the next node belongs to another dialog tree.
var _next_node_dialog: String = ""
## Node where the dialog was paused, to resume later.
var _paused_node: String = ""
## Stack of jump return frames.
var _jump_stack: Array[Dictionary] = []
## Loaded dialog branches that still need their resources released.
var _loaded_dialog_ids: Array[String] = []
## Current node being processing.
var _current_node: String = ""

## Flag to control if the dialog is running.
var _is_running: bool = false
## Flag to control if a dialogue is waiting to be continued.
var _awaiting_continue: bool = false
## Flag to control if the options are waiting to be selected.
var _awaiting_option: bool = false
## Flag to control if the dialog was set before entering the scene tree.
var _dialog_pending: bool = false


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	_initialize_interpreter()

	var sprouty_dialogs_manager = get_node_or_null("/root/SproutyDialogs")
	if sprouty_dialogs_manager:
		_resource_manager = sprouty_dialogs_manager.Resources

	# Load the resources if the dialog was set before entering the tree
	if _dialog_pending:
		_dialog_pending = false
		_load_dialog_resources(_start_id)


func _exit_tree() -> void:
	_release_dialog_resources()


func _initialize_interpreter() -> void:
	if _dialog_interpreter:
		return

	if SproutyDialogsSettingsManager.get_setting("use_custom_event_nodes"):
		var interpreter_path = SproutyDialogsReferenceUtils.get_reference_path(
				SproutyDialogsReferenceUtils.normalize_reference_dict(
					SproutyDialogsSettingsManager.get_setting("custom_event_interpreter")))
		# Use a custom event interpreter
		if not interpreter_path.is_empty():
			_dialog_interpreter = load(interpreter_path).new()

	if not _dialog_interpreter: # Create a event intepreter instance
		_dialog_interpreter = SproutyDialogsEventInterpreter.new()

	_dialog_interpreter.name = "EventInterpreter"
	_dialog_interpreter.continue_to_node.connect(_process_node)
	_dialog_interpreter.dialogue_processed.connect(_on_dialogue_processed)
	_dialog_interpreter.options_processed.connect(_on_options_processed)
	_dialog_interpreter.jump_to_node.connect(_on_jump_to_node)
	_dialog_interpreter.print_debug = print_debug
	add_child(_dialog_interpreter)


#region === Run dialog =========================================================

## Set the dialogue data and start ID to play a dialog tree.
## This method loads the dialog resources and prepares the runner to process
## the dialog tree before calling the [method play] method.
func set_dialog(dialog_data: SproutyDialogsDialogueData, start_id: String) -> void:
	if not dialog_data:
		printerr("[Sprouty Dialogs] No dialogue data provided to set.")
		return

	_release_dialog_resources()
	_reset_execution_state()
	_dialog_pending = false
	_dialog_data = dialog_data
	_starts_ids = dialog_data.get_start_ids()
	_start_id = start_id

	if not _starts_ids.has(_start_id): # Check if the dialog with given id exists
		printerr("[Sprouty Dialogs] Cannot find'" + _start_id + "'ID on dialogue data.")
		_start_id = ""
		_dialog_data = null
		_starts_ids = []
		_dialog_pending = false
		return

	if not is_inside_tree():
		_dialog_pending = true
		return

	_load_dialog_resources(_start_id)


## Clear the current dialogue data and release its resources.
func clear_dialog() -> void:
	_is_running = false
	_dialog_pending = false
	_reset_execution_state()
	_release_dialog_resources()
	_dialog_data = null
	_start_id = ""
	_starts_ids.clear()


## Plays the dialog tree.
## [br][br]Need to set the [member _dialog_data] and [member _start_id] before
## calling this method.
func play() -> void:
	if not _dialog_data: # Check if dialogue data is set
		printerr("[Sprouty Dialogs] No dialogue data set to play.")
		return
	if not _starts_ids.has(_start_id): # Check if the dialog with given id exists
		printerr("[Sprouty Dialogs] Cannot find'" + _start_id + "'ID on dialogue data.")
		return

	if not _loaded_dialog_ids.has(_start_id):
		if _resource_manager and not _resource_manager.is_node_ready():
			await _resource_manager.ready
		_load_dialog_resources(_start_id)

	_reset_execution_state()

	# Search for start node and start processing from there
	for node in _dialog_data.graph_data[_start_id]:
		if node.contains("start_node"):
			if print_debug:
				print("[Sprouty Dialogs] Starting dialog with ID: " + _start_id)
			_is_running = true
			_process_node(node)
			dialog_started.emit()
			break


## Continue to the next node after a dialogue was requested.
func continue_dialogue() -> void:
	if not _is_running:
		return
	if not _awaiting_continue:
		return
	_awaiting_continue = false
	_process_node(_next_node)


## Select an option after an options node was processed.
## The [param option_index] is the index of the selectable option, excluding
## the disabled options.
func select_option(option_index: int) -> void:
	if not _is_running:
		return
	if not _awaiting_option:
		return
	if option_index < 0 or option_index >= _next_options.size():
		printerr("[Sprouty Dialogs] Cannot select option at index " \
				+ str(option_index) + ". The option is not available.")
		return
	if not _dialog_data:
		return

	_awaiting_option = false
	var option_key = ""
	if option_index < _current_option_keys.size():
		option_key = _current_option_keys[option_index]
	else:
		option_key = _start_id + "_OPT" \
				+ _current_node.split("_")[-1] + "_" + str(option_index + 1)

	var option_dialog: Dictionary = {}
	if _dialog_data.dialogs.has(option_key):
		option_dialog = _dialog_data.dialogs[option_key]
	else:
		printerr("[Sprouty Dialogs] Cannot find the selected option '" \
				+ option_key + "' in the dialogue data.")
	option_dialog["key"] = option_key

	option_selected.emit(option_index + 1, option_dialog)
	_process_node(_next_options[option_index])


## Pause processing the dialog tree.
func pause() -> void:
	if print_debug: print("[Sprouty Dialogs] Dialog paused.")
	_is_running = false
	# If the dialogue is not waiting for a continuation or option, save the
	# current node to resume later
	if not _awaiting_continue and not _awaiting_option and _current_node != "":
		_paused_node = _current_node
	dialog_paused.emit()


## Resume processing the dialog tree.
func resume() -> void:
	if print_debug: print("[Sprouty Dialogs] Dialog resumed.")
	_is_running = true
	if not _awaiting_continue and not _awaiting_option and _paused_node != "":
		var paused_node = _paused_node
		_paused_node = ""
		_process_node(paused_node)
	dialog_resumed.emit()


## Stop processing the dialog tree and release its resources.
func stop() -> void:
	if print_debug: print("[Sprouty Dialogs] Dialog ended.")
	_is_running = false
	_reset_execution_state()
	_release_dialog_resources()
	dialog_ended.emit()


## Check if the dialog is running.
func is_running() -> bool:
	return _is_running


## Returns the current node being processed.
func get_current_node() -> String:
	return _current_node


## Returns the dialogue data resource being processed.
func get_dialog_data() -> SproutyDialogsDialogueData:
	return _dialog_data


## Returns the start ID of the dialog tree being processed.
func get_start_id() -> String:
	return _start_id


## Returns character data for a given character key name.
func get_character_data(key_name: String) -> SproutyDialogsCharacterData:
	if _resource_manager:
		var character_data = _resource_manager.get_character_data(key_name)
		if character_data:
			return character_data
	return null


## Returns the dialog box provided for the presentation layer, if any.
## This is used by the wait node to keep working with the existing interpreter.
func get_current_dialog_box() -> Node:
	if dialog_box_getter.is_valid():
		return dialog_box_getter.call()
	return null

#endregion

#region === Process graph ======================================================

## Process the next node on dialog tree.
func _process_node(node_name: String) -> void:
	if not _is_running: return
	# Check if the node is the end node
	if node_name == "END":
		if _jump_stack.size() > 0:
			var jump_frame = _jump_stack.pop_back()
			_start_id = jump_frame["start_id"]
			_next_node_dialog = jump_frame["next_node_dialog"]
			_dialog_data = jump_frame["dialog_data"]
			_starts_ids = _dialog_data.get_start_ids()
			var return_node = jump_frame["return_node"]
			if return_node == "" or return_node == "END":
				_process_node("END")
			else:
				_process_node(return_node)
			return
		stop()
		return
	_current_node = node_name
	# Get the node type to process
	var node_type = node_name.split("_node_")[0] + "_node"
	var node_data = {}

	# Try to find the node in the current dialog data
	if _dialog_data.graph_data[_start_id].has(node_name):
		node_data = _dialog_data.graph_data[_start_id][node_name]
	# If the node is not found in the current dialog, check if it has a reference to another dialog
	elif _next_node_dialog != "" and _dialog_data.graph_data.has(_next_node_dialog):
		node_data = _dialog_data.graph_data[_next_node_dialog].get(node_name, {})
		_start_id = _next_node_dialog # Update the start ID to the new dialog reference
		_starts_ids = _dialog_data.get_start_ids()

	if node_data == {}:
		printerr("[Sprouty Dialogs] Node '" + node_name + "' not found in dialog data.")
		return

	# If the next node has a reference to another dialog, update the reference
	_next_node_dialog = node_data.get("to_dialog", "")

	# Process the node with the dialog interpreter if it has a processor for the node type
	if _dialog_interpreter.node_processors.has(node_type):
		_dialog_interpreter.node_processors[node_type].call(node_data)
	else:
		printerr("[Sprouty Dialogs] Cannot process '" + node_name + "'. "
		+ "Go to Settings > General, check that the custom nodes are enabled, "
		+ "that the 'custom event interpreter' is setted and that it has the process "
		+ "method to run '" + node_type + "'.")
		# If the node type is not found, continue to the next node if there is one
		if node_data.has("to_node") and node_data["to_node"].size() > 0:
			_process_node(_dialog_data.graph_data[_start_id][node_name]["to_node"][0])


## Handle when a dialogue node is processed.
func _on_dialogue_processed(character_name: String, translated_name: String,
		portrait: String, dialog_data: Dictionary, next_node: String) -> void:
	_next_node = next_node
	_awaiting_continue = true
	dialogue_requested.emit(character_name, translated_name, portrait, dialog_data)


## Handle when the options node is processed.
func _on_options_processed(
		options: Array,
		next_nodes: Array,
		option_keys: Array = [],
		disabled_flags: Array = []
	) -> void:
	_next_options = []
	_current_option_keys = []

	for i in range(options.size()):
		var is_disabled: bool = i < disabled_flags.size() and bool(disabled_flags[i])
		if not is_disabled:
			_next_options.append(next_nodes[i])
			if i < option_keys.size():
				_current_option_keys.append(option_keys[i])

	_awaiting_option = true
	options_requested.emit(options, disabled_flags)


## Handle when a jump node is processed.
func _on_jump_to_node(start_node: String, start_id: String,
		return_node: String, dialog_data: SproutyDialogsDialogueData) -> void:
	if not _is_running:
		return

	var from_dialog_data = _dialog_data
	_dialog_data = dialog_data
	_starts_ids = _dialog_data.get_start_ids()

	if start_node.is_empty():
		start_node = _get_start_node_name(start_id)

	if start_node.is_empty() or start_id.is_empty():
		_process_node(return_node if return_node != "" else "END")
		return

	_jump_stack.append({
		"start_id": _start_id,
		"next_node_dialog": _next_node_dialog,
		"return_node": return_node,
		"dialog_data": from_dialog_data,
	})
	_start_id = start_id
	_next_node_dialog = ""
	_load_dialog_resources(start_id)
	_process_node(start_node)

#endregion

#region === Resource lifecycle =================================================

## Returns the name of the start node for a given dialog branch.
func _get_start_node_name(dialog_id: String) -> String:
	if not _dialog_data or not _dialog_data.graph_data.has(dialog_id):
		return ""
	for node_name in _dialog_data.graph_data[dialog_id].keys():
		if _dialog_data.graph_data[dialog_id][node_name]["node_type"] == "start_node":
			return node_name
	return ""


## Load the resources for a given dialog branch.
func _load_dialog_resources(dialog_id: String) -> void:
	if not _dialog_data or not _starts_ids.has(dialog_id):
		return
	if not _resource_manager:
		return
	_resource_manager.load_resources(_dialog_data, dialog_id)
	_loaded_dialog_ids.append(dialog_id)
	for node in _dialog_data.graph_data[dialog_id].keys():
		if _dialog_data.graph_data[dialog_id][node].has("to_dialog"):
			# If the node has a reference to another dialog, load its resources too
			var to_dialog = _dialog_data.graph_data[dialog_id][node]["to_dialog"]
			if to_dialog != "" and to_dialog != dialog_id:
				_resource_manager.load_resources(_dialog_data, to_dialog)
				_loaded_dialog_ids.append(to_dialog)


## Release all resources that were loaded for the active dialog branches.
func _release_dialog_resources() -> void:
	if not _resource_manager or not _dialog_data:
		_loaded_dialog_ids.clear()
		return
	for dialog_id in _loaded_dialog_ids:
		_resource_manager.release_resources(_dialog_data, dialog_id)
	_loaded_dialog_ids.clear()


## Reset the execution state without clearing the configured dialogue data.
func _reset_execution_state() -> void:
	_jump_stack.clear()
	_current_node = ""
	_paused_node = ""
	_next_node = ""
	_next_node_dialog = ""
	_next_options.clear()
	_current_option_keys.clear()
	_awaiting_continue = false
	_awaiting_option = false

#endregion

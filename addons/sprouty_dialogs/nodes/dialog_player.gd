@tool
@icon("res://addons/sprouty_dialogs/editor/icons/dialog_nodes/dialog_player.svg")
class_name DialogPlayer
extends Node

# -----------------------------------------------------------------------------
# Sprouty Dialogs Dialog Player
# -----------------------------------------------------------------------------
## Node that plays dialog trees from Sprouty Dialogs plugin.
##
## It reads a dialog file and processes a dialog tree by ID to play the dialog.
## The dialog tree is composed of nodes that represent dialogues and actions.
## The player processes the nodes and plays the dialogues in [DialogBox] nodes.
# -----------------------------------------------------------------------------

## Emitted when the dialog starts.
signal dialog_started(dialog_file: String, start_id: String)
## Emitted when the dialog is paused.
signal dialog_paused(dialog_file: String, start_id: String)
## Emitted when the dialog is resumed.
signal dialog_resumed(dialog_file: String, start_id: String)
## Emitted when the dialog is ended.
signal dialog_ended(dialog_file: String, start_id: String)

## Emitted when the dialog player stops.
signal dialog_player_stop(dialog_player: DialogPlayer)

## Emitted when a dialog option is selected.
signal option_selected(current_node: String, option_index: int)
## Emitted when a signal event is emitted.
signal signal_event(argument: String)

## UID of the dialogue data resource to play.
@export_storage var _dialog_data_uid: int = -1
## Name of the dialogue data file being played.
@export_storage var _dialog_file_name: String = ""

## Dialogue data resource to play.
var _dialog_data: SproutyDialogsDialogueData:
	set(value):
		_dialog_data = value
		_start_id = "(Select a dialog)"
		if value:
			_dialog_data_uid = ResourceLoader.get_resource_uid(value.resource_path)
			_dialog_file_name = value.resource_path.get_file().get_basename()
			_starts_ids = value.get_start_ids()
		else:
			_dialog_data_uid = -1
			_dialog_file_name = ""
			_starts_ids = []
		notify_property_list_changed()
## Start ID of the dialog tree to play.
var _start_id: String:
	set(value):
		_start_id = value
		if _dialog_data and _dialog_data.characters.has(value):
			for char in _dialog_data.characters[value]:
				_portrait_parents[char] = null
				_dialog_box_parents[char] = null
		notify_property_list_changed()

## Play the dialog when the node is ready.
var _play_on_ready: bool = false
## Flag to destroy the dialog player when the dialog ends.
## If true, the player will be freed from the scene tree when the dialog ends.
## If false, the player will remain in the scene tree to be reused later.
var _destroy_on_end: bool = true
## If true, will print debug messages to the console.
## This is used to debug the dialog processing flow while is running.
var _print_debug: bool = false

## Array to store the start IDs of the dialogues.
var _starts_ids: Array[String] = []

## Dictionary to store the portrait parent nodes by character.
## The keys are character names and the values are the parent nodes where
## the portraits will be displayed.
## The dictionary structure is:
## [codeblock]
## {
##   "character_name_1": Node reference,
##   "character_name_2": Node reference,
##   ...
## }[/codeblock]
var _portrait_parents: Dictionary = {}
## Dictionary to store the dialog box parent nodes by character.
## This is used if you want to display dialog boxes in some scene node
## instead of the default canvas layer to dialog boxes (override parent node).
## The keys are character names and the values are the parent nodes where
## the dialog boxes will be displayed.
## The dictionary structure is:
## [codeblock]
## {
##   "character_name_1": Node reference,
##   "character_name_2": Node reference,
##   ...
## }[/codeblock]
var _dialog_box_parents: Dictionary = {}

## Dictionary to store the dialog boxes displayed by character.
## The keys are character names and the values are the [DialogBox] instances.
## The dictionary structure is:
## [codeblock]
## {
##   "character_name_1": DialogBox instance,
##   "character_name_2": DialogBox instance,
##   ...
## }[/codeblock]
var _dialog_box_instances: Dictionary = {}
## Dictionary to store the portraits displayed by character.
## The keys are character names and the values are dictionaries with portrait
## names as keys and [DialogPortrait] instances as values.
## The dictionary structure is:
## [codeblock]
## {
##   "character_name_1": {
##     "portrait_name_1": DialogPortrait instance,
##     "portrait_name_2": DialogPortrait instance,
##     ...
##   },
##   ...
## }[/codeblock]
var _portraits_instances: Dictionary = {}

## Dialog interpreter instance to process the dialog nodes.
var _dialog_interpreter: SproutyDialogsEventInterpreter
## Resource manager instance used to load resources for the dialogs.
var _resource_manager: SproutyDialogsResourceManager

## Current dialog box being displayed.
var _current_dialog_box: DialogBox
## Current portrait being displayed.
var _current_portrait: DialogPortrait

## Next nodes options to process when a dialog option is selected.
var _next_options: Array = []
## Next node to process in the dialog tree after a dialogue node.
var _next_node: String = ""
## Node where the dialog was paused, to resume later.
var _paused_node: String = ""
## Current node being processing
var _current_node: String = ""

## Flag to control if the dialog is running.
var _is_running: bool = false


func _enter_tree() -> void:
	if not Engine.is_editor_hint(): # Only run in game
		_dialog_interpreter = SproutyDialogsEventInterpreter.new()
		_dialog_interpreter.continue_to_node.connect(_process_node)
		_dialog_interpreter.dialogue_processed.connect(_on_dialogue_processed)
		_dialog_interpreter.options_processed.connect(_on_options_processed)
		_dialog_interpreter.signal_processed.connect(_on_signal_processed)
		_dialog_interpreter.print_debug = _print_debug
		add_child(_dialog_interpreter)

		_resource_manager = get_node("/root/SproutyDialogs").get_resource_manager()


func _exit_tree() -> void:
	if _resource_manager:
		_resource_manager.release_resources(_dialog_data, _start_id)


func _ready() -> void:
	if Engine.is_editor_hint():
		# In editor, check if the dialogue data resource exists
		if not SproutyDialogsFileUtils.check_valid_uid_path(_dialog_data_uid):
			printerr("[Sprouty Dialogs] Dialog Player '" + name
				+"' cannot find the dialogue data resource '" \
				+ _dialog_file_name + ".tres'. Check if it was deleted.")
			_dialog_data = null
			_dialog_data_uid = -1
			_dialog_file_name = ""
			_start_id = "(Select a dialog)"
			_starts_ids = []
	else: # In game, load the dialogue data resources
		if not _dialog_data and SproutyDialogsFileUtils.check_valid_uid_path(_dialog_data_uid):
			_dialog_data = load(ResourceUID.get_id_path(_dialog_data_uid))
			_starts_ids = _dialog_data.get_start_ids()
		if _starts_ids.has(_start_id):
			if not _resource_manager.is_node_ready():
				await _resource_manager.ready
			_resource_manager.load_resources(_dialog_data, _start_id)
			# Start processing the dialog tree if the play on ready is enabled
			if _play_on_ready:
				start()
		elif _start_id == "(Select a dialog)":
			printerr("[Sprouty Dialogs] No dialog ID selected to play.")
			return


## Set play on ready flag to play the dialog when the node is ready.
## If true, the dialog will start processing when the dialog player node is ready.
func play_on_ready(play_on_ready: bool) -> void:
	_play_on_ready = play_on_ready


## Set the flag to destroy the dialog player when the dialog ends.
## If true, the player will be freed from the scene tree when the dialog ends.
## If false, the player will remain in the scene tree to be reused later.
func destroy_on_end(destroy: bool) -> void:
	_destroy_on_end = destroy


## Returns the dialogue data resource being processed
func get_dialog_data() -> SproutyDialogsDialogueData:
	return _dialog_data


## Returns the start ID of the dialog tree being processed
func get_start_id() -> String:
	if _start_id == "(Select a dialog)":
		return ""
	return _start_id


## Returns character data for a given character key name
func get_character_data(key_name: String) -> SproutyDialogsCharacterData:
	if _resource_manager:
		var character_data = _resource_manager.get_character_data(key_name)
		if character_data:
			return character_data
	return null


## Returns the current portrait being displayed
func get_current_portrait() -> DialogPortrait:
	return _current_portrait


## Returns the current dialog box being displayed
func get_current_dialog_box() -> DialogBox:
	return _current_dialog_box


## Set the dialogue data and start ID to play a dialog tree.
## This method loads the dialog resources and prepares the player to process
## the dialog tree before calling the [method DialogPlayer.start()]method.
func set_dialog(data: SproutyDialogsDialogueData, start_id: String,
		portrait_parents: Dictionary = {}, dialog_box_parents: Dictionary = {}) -> void:
	if not data:
		printerr("[Sprouty Dialogs] No dialogue data provided to set.")
		return
	_dialog_data = data
	_start_id = start_id

	if not _starts_ids.has(_start_id): # Check if the dialog with given id exists
		printerr("[Sprouty Dialogs] Cannot find'" + _start_id + "'ID on dialogue data.")
		_start_id = "(Select a dialog)"
		_dialog_data = null
		return
	
	if not portrait_parents.is_empty():
		_portrait_parents = portrait_parents
	if not dialog_box_parents.is_empty():
		_dialog_box_parents = dialog_box_parents
	
	# Load the resources
	_resource_manager.load_resources(_dialog_data, _start_id)


#region === Editor properties ==================================================
## Set extra properties on editor
func _get_property_list():
	if Engine.is_editor_hint():
		var props = []
		props.append({
			"name": &"_dialog_data",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "SproutyDialogsDialogueData"
		})
		# Set available start IDs to select
		if _dialog_data:
			var id_list = ""
			for id in _starts_ids:
				id_list += id
				if id != _starts_ids[-1]:
					id_list += ", "
			props.append({
				"name": &"_start_id",
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": id_list
			})
			props.append({
				"name": &"_play_on_ready",
				"type": TYPE_BOOL,
				"hint": PROPERTY_HINT_NONE,
				"usage": PROPERTY_USAGE_DEFAULT
			})
			props.append({
				"name": &"_destroy_on_end",
				"type": TYPE_BOOL,
				"hint": PROPERTY_HINT_NONE,
				"usage": PROPERTY_USAGE_DEFAULT
			})
			props.append({
				"name": &"_print_debug",
				"type": TYPE_BOOL,
				"hint": PROPERTY_HINT_NONE,
				"usage": PROPERTY_USAGE_DEFAULT
			})
			# Set characters options by dialog
			if not _start_id.is_empty() and _start_id in _dialog_data.characters:
				props.append({
				"name": "Override Display Parents",
				"type": TYPE_STRING,
				"usage": PROPERTY_USAGE_GROUP,
				"hint_string": "char_",
				})
				for char in _dialog_data.characters[_start_id]:
					props.append({ # Set a group by character name
						"name": char.capitalize(),
						"type": TYPE_STRING,
						"usage": PROPERTY_USAGE_SUBGROUP,
						"hint_string": char,
					})
					props.append({ # Set portrait parent node path by character
						"name": char + "_portraits_parent",
						"type": TYPE_OBJECT,
						"usage": PROPERTY_USAGE_DEFAULT,
						"hint": PROPERTY_HINT_NODE_TYPE,
						"hint_string": "Node",
					})
					props.append({ # Set dialogue box node path by character
						"name": char + "_dialog_box_parent",
						"type": TYPE_OBJECT,
						"usage": PROPERTY_USAGE_DEFAULT,
						"hint": PROPERTY_HINT_NODE_TYPE,
						"hint_string": "Node",
					})
		return props


func _get(property: StringName):
	# Show the portrait parent node path by character
	if property.ends_with("_portraits_parent"):
		var char_name = property.get_slice("_portraits_", 0)
		return _portrait_parents[char_name]

	# Show the dialogue box node path by character
	if property.ends_with("_dialog_box_parent"):
		var char_name = property.get_slice("_dialog_", 0)
		return _dialog_box_parents[char_name]


func _set(property: StringName, value: Variant) -> bool:
	# Storing the portrait parent node path by character
	if property.ends_with("_portraits_parent"):
		var char_name = property.get_slice("_portraits_", 0)
		_portrait_parents[char_name] = value
		return true
	
	# Storing the dialogue box node path by character
	if property.ends_with("_dialog_box_parent"):
		var char_name = property.get_slice("_dialog_", 0)
		_dialog_box_parents[char_name] = value
		return true
	return false

#endregion

#region === Run dialog =========================================================

## Start processing a dialog tree
## Need to set the [member DialogPlayer._dialog_data] and [member DialogPlayer._start_id] 
## before calling this method. The resources are loaded on the [method _ready()] method,
func start() -> void:
	if not _dialog_data: # Check if dialogue data is set
		printerr("[Sprouty Dialogs] No dialogue data set to play.")
		return
	if not _starts_ids.has(_start_id): # Check if the dialog with given id exists
		printerr("[Sprouty Dialogs] Cannot find'" + _start_id + "'ID on dialogue data.")
		return
	
	# Search for start node and start processing from there
	for node in _dialog_data.graph_data[_start_id]:
		if node.contains("start_node"):
			if print_debug:
				print("[Sprouty Dialogs] Starting dialog with ID: " + _start_id)
			_is_running = true
			_process_node(node)
			get_node("/root/SproutyDialogs").set_dialog_player_as_running(self)
			dialog_started.emit(_dialog_file_name, _start_id)
			break


## Pause processing the dialog tree
func pause() -> void:
	if print_debug: print("[Sprouty Dialogs] Dialog paused.")
	_is_running = false
	# If there is a current dialog box, pause it
	if _current_dialog_box:
		_current_dialog_box.pause_dialog()
		if _current_portrait:
			_current_portrait.on_portrait_stop_talking()
	# If not, save the current node to resume later
	elif _current_node != "":
		_paused_node = _current_node
	dialog_paused.emit(_dialog_file_name, _start_id)


## Resume processing the dialog tree
func resume() -> void:
	if print_debug: print("[Sprouty Dialogs] Dialog resumed.")
	_is_running = true
	# If there is a current dialog box, resume it
	if _current_dialog_box:
		_current_dialog_box.resume_dialog()
		if _current_portrait:
			_current_portrait.on_portrait_talk()
	# If there is no dialog box, but there is a paused node, continue the flow
	elif _paused_node != "":
		_process_node(_paused_node)
		_paused_node = ""
	dialog_resumed.emit(_dialog_file_name, _start_id)


## Stop processing the dialog tree
func stop() -> void:
	if print_debug: print("[Sprouty Dialogs] Dialog ended.")
	_is_running = false
	_current_portrait = null
	_current_node = ""
	_paused_node = ""
	_next_node = ""

	if not _current_dialog_box.is_displaying_portrait():
		await _current_dialog_box.stop_dialog(true)
		_current_dialog_box = null
	
	# Exit all active portraits
	for char in _portraits_instances.keys():
		for portrait in _portraits_instances[char].values():
			if portrait and portrait.is_visible():
				await portrait.on_portrait_exit()
	
	# Free all portraits displayed
	for char in _portraits_instances.keys():
		for portrait in _portraits_instances[char].values():
			if portrait:
				portrait.get_parent().queue_free()
	
	if _current_dialog_box: # If there is a current dialog box, stop it
		await _current_dialog_box.stop_dialog(true)
		_current_dialog_box = null
	
	# Free all dialog boxes displayed
	for dialog_box in _dialog_box_instances.values():
		dialog_box.queue_free()
	
	_portraits_instances.clear()
	_dialog_box_instances.clear()
	dialog_ended.emit(_dialog_file_name, _start_id)
	dialog_player_stop.emit(self)
	if _destroy_on_end:
		queue_free()


## Check if the dialog is running
func is_running() -> bool:
	return _is_running

#endregion

#region === Process graph ======================================================

## Process the next node on dialog tree
func _process_node(node_name: String) -> void:
	if not _is_running: return
	# Check if the node is the end node
	if node_name == 'END':
		stop()
		return
	_current_node = node_name
	# Get the node type to process
	var node_type = node_name.split("_node_")[0] + "_node"
	_dialog_interpreter.node_processors[node_type].call(
		_dialog_data.graph_data[_start_id][node_name]
		)


## Play dialog when the dialogue node is processed
func _on_dialogue_processed(character_name: String, translated_name: String,
		portrait: String, dialog: String, next_node: String) -> void:
	_next_node = next_node
	_update_dialog_box(character_name)
	await _update_portrait(character_name, portrait)
	_current_dialog_box.play_dialog(character_name, translated_name, dialog)


## Handle when the options node is processed
func _on_options_processed(options: Array, next_nodes: Array) -> void:
	if not _current_dialog_box:
		_update_dialog_box("") # Use default dialog box
	_current_dialog_box.display_options(options)
	_next_options = next_nodes


## Process the next node of the option selected
func _on_option_selected(option_index: int) -> void:
	_current_dialog_box.hide_options()
	option_selected.emit(_current_node, option_index)
	_process_node(_next_options[option_index])


## Emit a signal event when the signal node is processed
func _on_signal_processed(signal_argument: String, next_node: String) -> void:
	signal_event.emit(signal_argument)
	_next_node = next_node
	_process_node(_next_node)


## Continue to the next node in the dialog tree
func _on_continue_dialog() -> void:
	_process_node(_next_node)

#endregion

#region === Dialog box and portrait management =================================

## Update the dialog box for the current character
func _update_dialog_box(character_name: String) -> void:
	var dialog_box = null

	# Check if the dialog box is already loaded
	if _dialog_box_instances.has(character_name):
		dialog_box = _dialog_box_instances[character_name]
	else: # If the dialog box is not loaded, instantiate it
		dialog_box = _resource_manager.instantiate_dialog_box(
				character_name, _dialog_box_parents.get(character_name, null))
		_dialog_box_instances[character_name] = dialog_box
	
	# Check if the dialog box is already playing a dialog
	if _current_dialog_box and dialog_box != _current_dialog_box:
		_current_dialog_box.stop_dialog() # End the current dialog

	# Connect the dialog box signals
	if not dialog_box.is_connected("continue_dialog", _on_continue_dialog):
		dialog_box.continue_dialog.connect(_on_continue_dialog)
		dialog_box.dialog_typing_ends.connect(_on_dialog_typing_ends)
		dialog_box.dialog_starts.connect(_on_dialog_display_starts)
		dialog_box.dialog_ends.connect(_on_dialog_display_ends)
		dialog_box.option_selected.connect(_on_option_selected)
	
	_current_dialog_box = dialog_box


## Update the portrait for the current character
func _update_portrait(character_name: String, portrait_name: String) -> void:
	if character_name.is_empty() or portrait_name.is_empty():
		_current_portrait = null
		return

	var is_joining = false
	# Check if the character is joining the dialog
	if not _portraits_instances.has(character_name):
		_portraits_instances[character_name] = {}
		is_joining = true
	
	# If the portrait is already loaded, use it
	if _portraits_instances[character_name].has(portrait_name):
		_current_portrait = _portraits_instances[character_name][portrait_name]

	else: # Instantiate the portrait scene if not already loaded
		_current_portrait = _resource_manager.instantiate_portrait(character_name,
		portrait_name, _portrait_parents.get(character_name, null), _current_dialog_box)
		_portraits_instances[character_name][portrait_name] = _current_portrait
	
	if _current_portrait:
		_current_portrait.set_portrait()
	
	# Hide all other portraits of the character
	for portrait in _portraits_instances[character_name].values():
		if not portrait:
			continue
		if portrait != _current_portrait:
			portrait.hide()
		else:
			portrait.show()
	
	if is_joining and _current_portrait: # Entry action if the character is joining the dialog
		await _current_portrait.on_portrait_entry()


## Handle when the dialog display starts for a character.
func _on_dialog_display_starts(character_name: String) -> void:
	if _current_portrait and _current_portrait.get_parent().name == character_name:
		_current_portrait.on_portrait_talk()


## Handle when the dialog display ends for a character.
func _on_dialog_display_ends(character_name: String) -> void:
	if _current_portrait and _current_portrait.get_parent().name == character_name:
		_current_portrait.unhighlight_portrait()


## Handle when the dialog typing ends for a character.
func _on_dialog_typing_ends(character_name: String) -> void:
	if _current_portrait and _current_portrait.get_parent().name == character_name:
		_current_portrait.on_portrait_stop_talking()

#endregion

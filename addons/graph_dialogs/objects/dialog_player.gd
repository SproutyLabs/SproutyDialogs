@tool
@icon("res://addons/graph_dialogs/icons/icon.svg")
class_name DialogPlayer
extends Node

# -----------------------------------------------------------------------------
## Dialog Player
##
## It reads a dialog data file and processes a dialog tree to play the dialogues.
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
## Emitted when the dialog player stop.
signal dialog_player_stop(dialog_player: DialogPlayer)

## Dialog Data resource to play.
var _dialog_data: GraphDialogsDialogueData:
	set(value):
		_dialog_data = value
		_start_id = "(Select a dialog)"
		if value: _starts_ids = value.get_start_ids()
		_dialog_file_name = value.resource_path.get_file().get_basename()
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
## Dictionary to store the portraits displayed by character.
## This is used if you want to display portraits in some scene node
## instead of the default canvas layer to portraits (override parent node).
## The keys are character names and the values are dictionaries with portrait names
## as keys and [DialogPortrait] scenes loaded as values.
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
var _portraits_displayed: Dictionary = {}
## Name of the dialog file being played.
var _dialog_file_name: String = ""

## Dialog parser instance to process the dialog nodes.
var _dialog_parser: DialogParser
## Resource manager instance used to load resources for the dialogs.
var _resource_manager: GraphDialogsResourceManager

## Current dialog box being displayed.
var _current_dialog_box: DialogBox
## Current portrait being displayed.
var _current_portrait: DialogPortrait

## Current node being processing
var _current_node: String = ""
## Next node to process in the dialog tree after a dialogue node.
var _next_node: String = ""
## Node where the dialog was paused, to resume later.
var _paused_node: String = ""

## Flag to control if the dialog is running.
var _is_running: bool = false


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		_dialog_parser = DialogParser.new() # Initialize dialog parser
		add_child(_dialog_parser)
		_dialog_parser.continue_to_node.connect(_process_node)
		_dialog_parser.dialogue_processed.connect(_on_dialogue_processed)
		_resource_manager = get_node("/root/GraphDialogs").get_resource_manager(owner)


func _ready() -> void:
	if not Engine.is_editor_hint():
		# Load the dialog resources if the dialog data and start ID are set
		if _dialog_data and _starts_ids.has(_start_id):
			await _resource_manager.ready
			_resource_manager.load_resources(_dialog_data, _start_id, _dialog_box_parents)
			# Start processing the dialog tree if the play on ready is enabled
			if _play_on_ready:
				if _start_id == "(Select a dialog)":
					printerr("[Graph Dialogs] No dialog ID selected to play.")
					return
				start()


## Set play on ready flag to play the dialog when the node is ready.
## If true, the dialog will start processing when the dialog player node is ready.
func play_on_ready(play_on_ready: bool) -> void:
	_play_on_ready = play_on_ready


## Set the flag to destroy the dialog player when the dialog ends.
## If true, the player will be freed from the scene tree when the dialog ends.
## If false, the player will remain in the scene tree to be reused later.
func destroy_on_end(destroy: bool) -> void:
	_destroy_on_end = destroy


## Returns the dialog data resource being processed
func get_dialog_data() -> GraphDialogsDialogueData:
	return _dialog_data


## Returns the start ID of the dialog tree being processed
func get_start_id() -> String:
	if _start_id == "(Select a dialog)":
		return ""
	return _start_id


## Returns the current character name being processed
func get_current_character() -> String:
	if _current_portrait:
		return _current_portrait.get_parent().name
	return ""


## Returns the current portrait being displayed
func get_current_portrait() -> DialogPortrait:
	return _current_portrait


## Returns the character data for a given character name.
## This will return the character data from the dialog data resource
## being processed, if the character exists in the dialog data.
## If the character does not exist, it will return null.
func get_character_data(character: String) -> GraphDialogsCharacterData:
	return _resource_manager.get_character_data(character)


## Set the dialog data and start ID to play a dialog tree.
## This method loads the dialog resources and prepares the player to process
## the dialog tree before calling the [method DialogPlayer.start()]method.
func set_dialog(data: GraphDialogsDialogueData, start_id: String,
		portrait_parents: Dictionary = {}, dialog_box_parents: Dictionary = {}) -> void:
	if not data:
		printerr("[Graph Dialogs] No dialog data provided to set.")
		return
	_dialog_data = data
	_start_id = start_id

	if not _starts_ids.has(_start_id): # Check if the dialog with given id exists
		printerr("[Graph Dialogs] Cannot find '" + _start_id + "' ID on dialog file.")
		_start_id = "(Select a dialog)"
		_dialog_data = null
		return
	
	if not portrait_parents.is_empty():
		_portrait_parents = portrait_parents
	if not dialog_box_parents.is_empty():
		_dialog_box_parents = dialog_box_parents
	
	# Load the resources
	_resource_manager.load_resources(_dialog_data, _start_id, _dialog_box_parents)


#region === Editor properties ==================================================

## Set extra properties on editor
func _get_property_list():
	if Engine.is_editor_hint():
		var props = []
		props.append({
			"name": &"_dialog_data",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "GraphDialogsDialogueData"
		})
		# Set available start IDs to select
		if _dialog_data:
			var id_list = ""
			for id in _starts_ids:
				id_list += id
				if id != _starts_ids[-1]:
					id_list += ","
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
						"hint": PROPERTY_HINT_NODE_TYPE,
						"hint_string": "Node",
					})
					props.append({ # Set dialogue box node path by character
						"name": char + "_dialog_box_parent",
						"type": TYPE_OBJECT,
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

#region === Process graph ======================================================

## Start processing a dialog tree
## Need to set the [member DialogPlayer._dialog_data] and [member DialogPlayer._start_id] 
## before calling this method. The resources are loaded on the [method _ready()] method,
func start() -> void:
	if not _dialog_data: # Check if dialog data is set
		printerr("[Graph Dialogs] No dialog data set to play.")
		return
	if not _starts_ids.has(_start_id): # Check if the dialog with given id exists
		printerr("[Graph Dialogs] Cannot find '" + _start_id + "' ID on dialog file.")
		return
	
	# Search for start node and start processing from there
	for node in _dialog_data.graph_data[_start_id]:
		if node.contains("start_node"):
			print("[Graph Dialogs] Starting dialog with ID: " + _start_id)
			_is_running = true
			_process_node(node)
			get_node("/root/GraphDialogs").set_dialog_player_as_running(self)
			dialog_started.emit(_dialog_file_name, _start_id)
			break


## Pause processing the dialog tree
func pause() -> void:
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
	_is_running = false
	_current_portrait = null
	_current_node = ""
	_paused_node = ""
	_next_node = ""

	if not _current_dialog_box.is_displaying_portrait():
		await _current_dialog_box.stop_dialog(true)
		_current_dialog_box = null
	
	# Exit all active portraits
	for char in _portraits_displayed.keys():
		for portrait in _portraits_displayed[char].values():
			if portrait.is_visible():
				await portrait.on_portrait_exit()
	
	# Free all portraits displayed
	for char in _portraits_displayed.keys():
		for portrait in _portraits_displayed[char].values():
			portrait.get_parent().queue_free()
	
	if _current_dialog_box:
		await _current_dialog_box.stop_dialog(true)
		_current_dialog_box = null
	
	_portraits_displayed.clear()
	dialog_ended.emit(_dialog_file_name, _start_id)
	dialog_player_stop.emit(self)
	if _destroy_on_end:
		queue_free()


## Check if the dialog is running
func is_running() -> bool:
	return _is_running


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
	_dialog_parser.node_processors[node_type].call(
		_dialog_data.graph_data[_start_id][node_name]
		)


## Play dialog when the dialogue node is processed
func _on_dialogue_processed(character_name: String, translated_name: String,
		portrait: String, dialog: String, next_node: String) -> void:
	_next_node = next_node
	_update_dialog_box(character_name)
	await _update_portrait(character_name, portrait)
	_current_dialog_box.play_dialog(character_name, translated_name, dialog)


## Continue to the next node in the dialog tree
func _on_continue_dialog() -> void:
	_process_node(_next_node)

#endregion

#region === Dialog box and portrait management =================================

## Update the dialog box for the current character
func _update_dialog_box(character_name: String) -> void:
	var dialog_box = _resource_manager.get_dialog_box(_start_id, character_name)
	
	# Check if the dialog box is already playing a dialog
	if _current_dialog_box and dialog_box != _current_dialog_box:
		_current_dialog_box.stop_dialog() # End the current dialog

	# Connect the dialog box signals
	if not dialog_box.is_connected("continue_dialog", _on_continue_dialog):
		dialog_box.continue_dialog.connect(_on_continue_dialog)
		dialog_box.dialog_typing_ends.connect(_on_dialog_typing_ends)
		dialog_box.dialog_starts.connect(_on_dialog_display_starts)
		dialog_box.dialog_ends.connect(_on_dialog_display_ends)
	
	_current_dialog_box = dialog_box


## Update the portrait for the current character
func _update_portrait(character_name: String, portrait_name: String) -> void:
	if character_name.is_empty() or portrait_name.is_empty():
		_current_portrait = null
		return

	var is_joining = false
	# Check if the character is joining the dialog
	if not _portraits_displayed.has(character_name):
		_portraits_displayed[character_name] = {}
		is_joining = true
	
	# If the portrait is already loaded, use it
	if _portraits_displayed[character_name].has(portrait_name):
		_current_portrait = _portraits_displayed[character_name][portrait_name]

	else: # Instantiate the portrait scene if not already loaded
		_current_portrait = _resource_manager.instantiate_portrait(_start_id,
			character_name, portrait_name, _portrait_parents)
		_portraits_displayed[character_name][portrait_name] = _current_portrait
	
	_current_portrait.set_portrait()
	
	# Hide all other portraits of the character
	for portrait in _portraits_displayed[character_name].values():
		if portrait != _current_portrait:
			portrait.hide()
		else:
			portrait.show()
	
	if is_joining: # Entry action if the character is joining the dialog
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

@tool
@icon("res://addons/graph_dialogs/icons/icon.svg")
class_name DialogPlayer
extends Node

## -----------------------------------------------------------------------------
## Dialog Player
##
## It reads a dialog file and processes the dialog tree to play the dialogues.
## The dialog tree is composed of nodes that represent dialogues and actions.
## The player processes the nodes and plays the dialogues in the dialog boxes.
## -----------------------------------------------------------------------------

## Signal emitted when the dialog is started.
signal dialog_started(start_id: String)
## Signal emitted when the dialog is ended.
signal dialog_ended

## Dialog Data resource to play.
@export var dialog_data: GraphDialogsDialogueData:
	set(value):
		dialog_data = value
		if value: _starts_ids = value.get_start_ids()
		start_id = "(Select a dialog)"
		notify_property_list_changed()

## Start ID of the dialog to play.
var start_id: String:
	set(value):
		start_id = value
		if dialog_data and dialog_data.characters.has(value):
			for char in dialog_data.characters[value]:
				_portrait_parents[char] = null
				_dialog_box_parents[char] = null
		notify_property_list_changed()

## Play the dialog when the node is ready.
@export var play_on_ready: bool = false

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
## The keys are character names and the values are dictionaries with portrait names
## as keys and DialogPortrait scenes loaded as values.
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

## Current dialog box being displayed.
var _current_dialog_box: DialogBox
## Current portrait being displayed.
var _current_portrait: DialogPortrait

## Dialog parser instance to process the dialog nodes.
var _dialog_parser: DialogParser

## Current node being processing
var _current_node: String = ""
## Next node to process in the dialog tree after a dialogue node.
var _next_node: String = ""
## Node where the dialog was paused, to resume later.
var _paused_node: String = ""

## Flag to control if the dialog is running.
var _is_running: bool = false


func _enter_tree() -> void:
	# Initialize dialog parser
	_dialog_parser = DialogParser.new()
	add_child(_dialog_parser)
	
	_dialog_parser.continue_to_node.connect(_process_node)
	_dialog_parser.dialogue_processed.connect(_on_dialogue_processed)


func _ready() -> void:
	# Play the dialog on ready if the property is set
	if not Engine.is_editor_hint():
		if start_id == "(Select a dialog)":
			printerr("[Graph Dialogs] No dialog ID selected to play.")
			return
		GraphDialogs.load_resources(dialog_data, start_id, _dialog_box_parents)
		if play_on_ready: start()


#region === Editor properties ==================================================
## Set extra properties on editor
func _get_property_list():
	if Engine.is_editor_hint():
		var props = []
		# Set available start IDs to select
		if dialog_data:
			var id_list = ""
			for id in _starts_ids:
				id_list += id
				if id != _starts_ids[-1]:
					id_list += ","
			props.append({
				"name": &"start_id",
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": id_list
			})
			# Set characters options by dialog
			if not start_id.is_empty() and start_id in dialog_data.characters:
				props.append({
				"name": "Anchors Settings",
				"type": TYPE_STRING,
				"usage": PROPERTY_USAGE_GROUP,
				"hint_string": "char_",
				})
				for char in dialog_data.characters[start_id]:
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

## Start processing a dialog tree by ID
func start(dialog_id: String = start_id) -> void:
	if not dialog_data: # Check if dialog data is set
		printerr("[Graph Dialogs] No dialog data set to play.")
		return
	if not _starts_ids.has(dialog_id): # Check if the dialog with given id exists
		printerr("[Graph Dialogs] Cannot find '" + dialog_id + "' ID on dialog file.")
		return

	# Search for start node and start processing from there
	for node in dialog_data.graph_data[dialog_id]:
		if node.contains("start_node"):
			print("[Graph Dialogs] Starting dialog with ID: " + dialog_id)
			_is_running = true
			_process_node(node)
			dialog_started.emit(dialog_id)
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


## Stop processing the dialog tree
func stop() -> void:
	_is_running = false
	_current_dialog_box.end_dialog()
	_current_dialog_box = null
	_current_portrait = null
	_current_node = ""
	_paused_node = ""
	_next_node = ""
	# Exit displayed portraits and free them
	for char in _portraits_displayed.keys():
		for portrait in _portraits_displayed[char].values():
			if portrait.is_visible():
				portrait.on_portrait_exit()
	for char in _portraits_displayed.keys():
		for portrait in _portraits_displayed[char].values():
			print("[Graph Dialogs] Freeing portraits from: " + portrait.get_parent().name)
			portrait.get_parent().queue_free()
	_portraits_displayed.clear()
	dialog_ended.emit()


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
		dialog_data.graph_data[start_id][node_name]
		)


## Play dialog when the dialogue node is processed
func _on_dialogue_processed(char: String, portrait: String, dialog: String, next_node: String) -> void:
	_next_node = next_node
	_update_dialog_box(char)
	_update_portrait(char, portrait)
	_current_dialog_box.start_dialog(char, dialog)


## Continue to the next node in the dialog tree
func _on_continue_dialog() -> void:
	_process_node(_next_node)

#endregion

#region === Dialog box and portrait management =================================

## Update the dialog box for the current character
func _update_dialog_box(character_name: String) -> void:
	var dialog_box = GraphDialogs.get_dialog_box(start_id, character_name)
	
	# Check if the dialog box is already playing a dialog
	if _current_dialog_box and dialog_box != _current_dialog_box:
		_current_dialog_box.end_dialog() # End the current dialog

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
		_current_portrait = GraphDialogs.instantiate_portrait(start_id,
			character_name, portrait_name, _portrait_parents[character_name])
		_portraits_displayed[character_name][portrait_name] = _current_portrait
	
	_current_portrait.set_portrait()

	if is_joining: # Entry action if the character is joining the dialog
		_current_portrait.on_portrait_entry()
	
	# Hide all other portraits of the character
	for portrait in _portraits_displayed[character_name].values():
		if portrait != _current_portrait:
			portrait.hide()
		else:
			portrait.show()


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

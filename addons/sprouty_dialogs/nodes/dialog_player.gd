@tool
@icon("res://addons/sprouty_dialogs/editor/icons/nodes/dialog_player.svg")
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
signal dialog_started()
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

## Emitted when the dialog player stops.
signal dialog_player_stop()

## UID of the dialogue data resource to play.
@export_storage var _dialog_data_uid: int = -1
## Path to the dialogue data resource to play, stored as a fallback to load
## it when the UID is no longer valid.
@export_storage var _dialog_data_path: String = ""
## Name of the dialogue data file being played.
@export_storage var _dialog_file_name: String = ""

#region === Editor Properties ================================================== 

## Dialogue data resource to play.
var _dialog_data: SproutyDialogsDialogueData:
	set(value):
		_dialog_data = value
		if value:
			value.sync_character_references()
			_dialog_data_uid = ResourceLoader.get_resource_uid(value.resource_path)
			_dialog_data_path = value.resource_path
			_dialog_file_name = value.resource_path.get_file().get_basename()
			_starts_ids = value.get_start_ids()
		else:
			_dialog_data_uid = -1
			_dialog_data_path = ""
			_dialog_file_name = ""
			_starts_ids = []
		if Engine.is_editor_hint():
			_start_id = "(Select a dialog)"
			notify_property_list_changed()
			update_configuration_warnings()

## Start ID of the dialog tree to play.
var _start_id: String:
	set(value):
		_start_id = value
		_set_overrides_dictionaries()
		if Engine.is_editor_hint():
			notify_property_list_changed()
			update_configuration_warnings()

## If [code]true[/code], dialog plays when the node is ready.
##
## [br][br]It's the same as [method play_on_ready].[br][br]
## [i](This was added to follow the Godot conventions, without breaking existing API)
var autoplay: bool = false:
	set(value):
		autoplay = value
		_play_on_ready = value
	get:
		return _play_on_ready

## Flag to play the dialog when the node is ready.
var _play_on_ready: bool = false

## If [code]true[/code], the [DialogPlayer] will be freed from the scene tree when the dialog ends.
## [br] If [code]false[/code], the [DialogPlayer] will remain in the scene tree to be reused later.
##
## [br][br]It's the same as [method destroy_on_end].[br][br]
## [i](This was added to follow the Godot conventions, without breaking existing API)
var free_on_end: bool = true:
	set(value):
		free_on_end = value
		_destroy_on_end = value
	get:
		return _destroy_on_end
## Flag to destroy the dialog player when the dialog ends.
var _destroy_on_end: bool = true

#region === Advanced Settings ==================================================

## If [code]true[/code], the [DialogPlayer] will automatically continue to the next node after a dialog is displayed.
## [br][br]If [code]false[/code], the player will wait for the user to press the continue button to display the next dialog.
##
## [br][br]If the setting [code]Enabled at start[/code] is enabled, the [DialogPlayer] will start with auto-advance enabled
## ignoring the [member auto_advance] value set in the inspector.
var auto_advance: bool = false
## If [code]true[/code], the [DialogPlayer] will allow skipping the text reveal animation by pressing the continue button.
## [br][br]If [code]false[/code], the player will wait for the text reveal animation to finish before continue.
##
## [br][br]The setting [code]Allow Skip Text Reveal[/code] must be enabled to allow skipping the text reveal animation. 
var text_reveal_skippable: bool = true
## If [code]true[/code], the [DialogPlayer] will print debug messages to the console.
## This is used to debug the dialog processing flow while is running.
var print_debug: bool = false

#endregion

#endregion

#region === Display Overrides ==================================================

## [Node] to override the default portraits display parent node.
##
## [br][br]This is used if you want to display portraits in some scene node
## instead of the default canvas layer to portraits (override parent node).
## 
## [br][br][i]You can also set the parent node for each character individually below.
var _portraits_display_override: Node = null
## [Node] to override the default dialog box display parent node.
## 
## [br][br]This is used if you want to display dialog boxes in some scene node
## instead of the default canvas layer to dialog boxes (override parent node).
## 
## [br][br][i]You can also set the parent node for each character individually below.
var _dialog_box_display_override: Node = null
## [DialogBox] to override the default dialog box node used to display the dialog.
##
## [br][br]This is used if you want to use a custom dialog box node instead of the default one.[br]
## You can change the default dialog box in [b]Sprouty Dialogs Tab > Settings > Defaults[/b].
## 
## [br][br][i]You can also set the dialog box node for each character individually below.
## [br][br]Note: If you set a dialog box override for a character, it will override the 
## dialog box assigned in the character data resource for that character.
var _dialog_box_override: DialogBox = null
## If [code]true[/code], the [DialogPlayer] will ignore the display override 
## parent node for the overridden dialog box node.
## 
## [br][br]This is used if you want to use a custom dialog box node that is already
## placed in the scene tree and you don't want to change its parent node.
## 
## [br][br][i]Note: This only applies to the [member _dialog_box_override] node, 
## not the default dialog box, or the dialog boxes overridden for each character.
## [br][br][i]You can set the ignore display override flag for each character individually below.
var _ignore_dialog_box_display_override: bool = false
## Dictionary to store the portrait display parent nodes by character.
## This is used if you want to display dialog boxes in some scene node
## instead of the default canvas layer to dialog boxes (override parent node).
## The keys are character names and the values are the parent nodes where
## the portraits will be displayed.
## The dictionary structure is:
## [codeblock]
## {
##   "character_name_1": Node reference,
##   "character_name_2": Node reference,
##   ...
## }[/codeblock]
var _portraits_display_per_character: Dictionary = {}
## Dictionary to store the dialog box display parent nodes by character.
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
var _dialog_box_display_per_character: Dictionary = {}
## Dictionary to store the dialog box override nodes by character.
## This is used if you want to use a custom dialog box node instead of the default one.
## The keys are character names and the values follow the following structure:
## [codeblock]
## {
##   "character_name_1": {
##	    "dialog_box": DialogBox instance,
##		"ignore_display_override": bool,
##	},
##   "character_name_2": {
##	    "dialog_box": DialogBox instance,
##		"ignore_display_override": bool,
##	},
##   ...
## }[/codeblock]
var _dialog_box_override_per_character: Dictionary = {}

#endregion

#region === Internal Variables =================================================

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

## Array to store the start IDs of the dialogues.
var _starts_ids: Array[String] = []

## Runner instance that executes the dialogue trees.
var _runner: SproutyDialogsRunner
## Resource manager instance used to load resources for the dialogs.
var _resource_manager: SproutyDialogsResourceManager

## Current dialog box being displayed.
var _current_dialog_box: DialogBox
## Current portrait being displayed.
var _current_portrait: DialogPortrait

#endregion

#region === Handle Editor Properties ===========================================

## Handle editor warnings
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not _dialog_data: # Check if the node is empty or invalid
		warnings.push_back("A dialog data must be provided to play a dialogue. "
			+ "Please assign a '.tres' dialogue data file in the inspector.")
	elif not ResourceLoader.exists(
			SproutyDialogsReferenceUtils.get_reference_path_from_uid(
				_dialog_data_uid, _dialog_data_path)):
		warnings.push_back("The dialog data assigned is invalid, please check that the file exist.")
	elif _start_id == "(Select a dialog)":
		warnings.push_back("A start ID must be provided to play a dialogue. "
			+ "Please select a start ID in the inspector.")
	return warnings


## Set extra properties on editor
func _get_property_list():
	var props: Array[Dictionary] = []
	if Engine.is_editor_hint():
		# Main properties group ------------------------------------------------
		props.append({
			"name": &"_dialog_data",
			"type": TYPE_OBJECT,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "SproutyDialogsDialogueData"
		})
		if _dialog_data: # Set available start IDs to select
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
				"name": &"autoplay",
				"type": TYPE_BOOL,
				"hint": PROPERTY_HINT_NONE,
				"usage": PROPERTY_USAGE_DEFAULT
			})
			props.append({
				"name": &"free_on_end",
				"type": TYPE_BOOL,
				"hint": PROPERTY_HINT_NONE,
				"usage": PROPERTY_USAGE_DEFAULT
			})
			# Advanced settings group ------------------------------------------
			props.append({
				"name": "Auto Advance Settings",
				"type": TYPE_STRING,
				"usage": PROPERTY_USAGE_GROUP
			})
			props.append({
				"name": &"auto_advance",
				"type": TYPE_BOOL,
				"usage": PROPERTY_USAGE_DEFAULT
			})
			props.append({
				"name": &"text_reveal_skippable",
				"type": TYPE_BOOL,
				"usage": PROPERTY_USAGE_DEFAULT
			})
			props.append({
				"name": &"print_debug",
				"type": TYPE_BOOL,
				"usage": PROPERTY_USAGE_DEFAULT
			})
			# Dialog box overrides group ---------------------------------------
			props.append({
			"name": "Dialog Box Overrides",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_GROUP,
			})
			props.append({ # Set custom dialog box (general)
				"name": &"_dialog_box_override",
				"type": TYPE_OBJECT,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NODE_TYPE,
				"hint_string": "DialogBox",
			})
			props.append({ # Set dialog box ignore display override flag (general)
				"name": &"_ignore_dialog_box_display_override",
				"type": TYPE_BOOL,
				"usage": PROPERTY_USAGE_DEFAULT
			})
			if not _start_id.is_empty() and _start_id in _dialog_data.characters:
				for char in _dialog_data.characters[_start_id]:
					props.append({ # Set a group by character name
						"name": char.capitalize(),
						"type": TYPE_STRING,
						"usage": PROPERTY_USAGE_SUBGROUP,
						"hint_string": char,
					})
					props.append({ # Set dialog box node path by character
						"name": char + "_dialog_box_override",
						"type": TYPE_OBJECT,
						"usage": PROPERTY_USAGE_DEFAULT,
						"hint": PROPERTY_HINT_NODE_TYPE,
						"hint_string": "DialogBox",
					})
					props.append({ # Set ignore override flag by character
						"name": char + "_ignore_display_override",
						"type": TYPE_BOOL,
						"usage": PROPERTY_USAGE_DEFAULT
					})
			# Display overrides group ------------------------------------------
			props.append({
			"name": "Display Overrides",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_GROUP,
			})
			props.append({ # Set portrait display parent node (general)
				"name": &"_portraits_display_override",
				"type": TYPE_OBJECT,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NODE_TYPE,
				"hint_string": "Node",
			})
			props.append({ # Set dialog box display parent node (general)
				"name": &"_dialog_box_display_override",
				"type": TYPE_OBJECT,
				"usage": PROPERTY_USAGE_DEFAULT,
				"hint": PROPERTY_HINT_NODE_TYPE,
				"hint_string": "Node",
			})
			if not _start_id.is_empty() and _start_id in _dialog_data.characters:
				for char in _dialog_data.characters[_start_id]:
					props.append({ # Set a group by character name
						"name": char.capitalize(),
						"type": TYPE_STRING,
						"usage": PROPERTY_USAGE_SUBGROUP,
						"hint_string": char,
					})
					props.append({ # Set portrait parent node path by character
						"name": char + "_portraits_display",
						"type": TYPE_OBJECT,
						"usage": PROPERTY_USAGE_DEFAULT,
						"hint": PROPERTY_HINT_NODE_TYPE,
						"hint_string": "Node",
					})
					props.append({ # Set dialog box parent node path by character
						"name": char + "_dialog_box_display",
						"type": TYPE_OBJECT,
						"usage": PROPERTY_USAGE_DEFAULT,
						"hint": PROPERTY_HINT_NODE_TYPE,
						"hint_string": "Node",
					})
	return props


func _get(property: StringName):
	# Show the portrait parent node path by character
	if property.ends_with("_portraits_display") \
			or property.ends_with("_portraits_parent"):
		var char_name = property.get_slice("_portraits_", 0)
		return _portraits_display_per_character.get(char_name, null)

	# Show the dialog box parent node path by character
	if property.ends_with("_dialog_box_display") \
			or property.ends_with("_dialog_box_parent"):
		var char_name = property.get_slice("_dialog_", 0)
		return _dialog_box_display_per_character.get(char_name, null)
	
	# Show the dialog box node path by character
	if property.ends_with("_dialog_box_override"):
		var char_name = property.get_slice("_dialog_box_override", 0)
		return _dialog_box_override_per_character.get(char_name,
				{"dialog_box": null})["dialog_box"]
	
	# Show the ignore parent override flag by character
	if property.ends_with("_ignore_display_override"):
		var char_name = property.get_slice("_ignore_display_override", 0)
		return _dialog_box_override_per_character.get(char_name,
				{"ignore_display_override": null})["ignore_display_override"]

	return null


func _set(property: StringName, value: Variant) -> bool:
	# Storing the portrait parent node path by character
	if property.ends_with("_portraits_display") \
			or property.ends_with("_portraits_parent"):
		var char_name = property.get_slice("_portraits_", 0)
		_portraits_display_per_character[char_name] = value
		return true
	
	# Storing the dialog box parent node path by character
	if property.ends_with("_dialog_box_display") \
			or property.ends_with("_dialog_box_parent"):
		var char_name = property.get_slice("_dialog_", 0)
		_dialog_box_display_per_character[char_name] = value
		return true

	# Storing the dialog box node path by character
	if property.ends_with("_dialog_box_override"):
		var char_name = property.get_slice("_dialog_box_override", 0)
		if not _dialog_box_override_per_character.has(char_name):
			_dialog_box_override_per_character[char_name] = {
				"dialog_box": null,
				"ignore_display_override": false
			}
		_dialog_box_override_per_character[char_name]["dialog_box"] = value
		return true

	# Storing the ignore parent override flag by character
	if property.ends_with("_ignore_display_override"):
		var char_name = property.get_slice("_ignore_display_override", 0)
		if not _dialog_box_override_per_character.has(char_name):
			_dialog_box_override_per_character[char_name] = {
				"dialog_box": null,
				"ignore_display_override": false
			}
		_dialog_box_override_per_character[char_name]["ignore_display_override"] = value
		return true
	return false

#endregion


func _enter_tree() -> void:
	if not Engine.is_editor_hint(): # Only run in game
		var sprouty_dialogs_manager = get_node("/root/SproutyDialogs")
		_resource_manager = sprouty_dialogs_manager.Resources

		_create_runner()

		# Connect signals to autoload manager
		dialog_started.connect(func():
			sprouty_dialogs_manager.dialog_players_running.append(self)
			sprouty_dialogs_manager.dialog_started.emit()
		)
		dialog_player_stop.connect(sprouty_dialogs_manager.dialog_players_running.erase.bind(self))
		dialog_paused.connect(sprouty_dialogs_manager.dialog_paused.emit)
		dialog_resumed.connect(sprouty_dialogs_manager.dialog_resumed.emit)
		dialog_ended.connect(sprouty_dialogs_manager.dialog_ended.emit)
		option_selected.connect(sprouty_dialogs_manager.option_selected.emit)
		signal_event.connect(sprouty_dialogs_manager.signal_event.emit)

		# Load settings from the Sprouty Dialogs Settings Manager
		var auto_advance_enabled = SproutyDialogsSettingsManager.get_setting("auto_advance_enabled_at_start")
		if auto_advance_enabled != null:
			auto_advance = auto_advance_enabled or auto_advance
		var text_reveal_skippable_enabled = SproutyDialogsSettingsManager.get_setting("allow_skip_text_reveal")
		if text_reveal_skippable_enabled != null:
			text_reveal_skippable = text_reveal_skippable_enabled and text_reveal_skippable


## Create the runner that executes the dialogue trees and connect its signals.
func _create_runner() -> void:
	if _runner:
		return
	_runner = SproutyDialogsRunner.new()
	_runner.name = "SproutyDialogsRunner"
	_runner.print_debug = print_debug
	_runner.dialog_box_getter = func(): return _current_dialog_box
	_runner.dialog_started.connect(dialog_started.emit)
	_runner.dialogue_requested.connect(_on_dialogue_processed)
	_runner.options_requested.connect(_on_options_processed)
	_runner.dialog_paused.connect(_on_dialog_paused)
	_runner.dialog_resumed.connect(_on_dialog_resumed)
	_runner.dialog_ended.connect(_on_dialog_ended)
	_runner.option_selected.connect(option_selected.emit)
	_runner.signal_event.connect(signal_event.emit)
	add_child(_runner)


func _ready() -> void:
	var dialog_data_path = SproutyDialogsReferenceUtils.get_reference_path_from_uid(
			_dialog_data_uid, _dialog_data_path)
	if Engine.is_editor_hint():
		# In editor, check if the dialogue data resource exists
		if not ResourceLoader.exists(dialog_data_path):
			printerr("[Sprouty Dialogs] Dialog Player '" + name
				+ "' cannot find the dialogue data resource '" \
				+ _dialog_file_name + ".tres'. Check if it was deleted.")
			_dialog_data = null
			_dialog_data_uid = -1
			_dialog_data_path = ""
			_dialog_file_name = ""
			_start_id = "(Select a dialog)"
			_starts_ids = []
	else: # In game, load the dialogue data resources
		if not _dialog_data and ResourceLoader.exists(dialog_data_path):
			_dialog_data = load(dialog_data_path)
			if _dialog_data:
				_starts_ids = _dialog_data.get_start_ids()
		if _starts_ids.has(_start_id):
			if not _resource_manager.is_node_ready():
				await _resource_manager.ready
			_runner.set_dialog(_dialog_data, _start_id)
			# Start processing the dialog tree if the play on ready is enabled
			if _play_on_ready:
				play()
		elif _start_id == "(Select a dialog)":
			printerr("[Sprouty Dialogs] No dialog ID selected to play.")
			return


## If enabled, dialog plays when the node is ready.
## @deprecated: Use [member autoplay] instead.
func play_on_ready(enabled: bool) -> void:
	_play_on_ready = enabled
	autoplay = enabled


## If enabled, the [DialogPlayer] will be freed from the scene tree when the dialog ends.
## [br]Otherwise, the [DialogPlayer] will remain in the scene tree to be reused later.
## @deprecated: Use [member free_on_end] instead.
func destroy_on_end(enabled: bool) -> void:
	_destroy_on_end = enabled


## Returns the dialogue data resource being processed
func get_dialog_data() -> SproutyDialogsDialogueData:
	if _runner and _runner.get_dialog_data():
		return _runner.get_dialog_data()
	return _dialog_data


## Returns the start ID of the dialog tree being processed
func get_start_id() -> String:
	if _runner and not _runner.get_start_id().is_empty():
		return _runner.get_start_id()
	if _start_id == "(Select a dialog)":
		return ""
	return _start_id


## Returns character data for a given character key name
func get_character_data(key_name: String) -> SproutyDialogsCharacterData:
	if _runner:
		var runner_character_data = _runner.get_character_data(key_name)
		if runner_character_data:
			return runner_character_data
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


## Returns the parent node where the portraits will be displayed for a given character.
## If no character name is provided, it returns the default overrided parent node 
## for all characters (If is set, otherwise it returns null).
func get_portraits_display_override(character_name: String = "") -> Node:
	if character_name == "":
		return _portraits_display_override
	if _portraits_display_per_character.has(character_name):
		return _portraits_display_per_character[character_name]
	return null


## Returns the parent node where the dialog box will be displayed for a given character.
## If no character name is provided, it returns the default overrided parent node
## for all characters (If is set, otherwise it returns null).
func get_dialog_box_display_override(character_name: String = "") -> Node:
	if character_name == "":
		return _dialog_box_display_override
	if _dialog_box_display_per_character.has(character_name):
		return _dialog_box_display_per_character[character_name]
	return null


## Returns the dialog box node to be used for a given character.
## If no character name is provided, it returns the default overrided dialog box
## node for all characters (If is set, otherwise it returns null).
func get_dialog_box_override(character_name: String = "") -> DialogBox:
	if character_name == "":
		return _dialog_box_override
	if _dialog_box_override_per_character.has(character_name):
		return _dialog_box_override_per_character[character_name]["dialog_box"]
	return null


## Set the parent node where the portraits will be displayed for a given character.
## If no character name is provided, it sets the default overrided parent node
## for all characters (If is set, otherwise it returns null).
func set_portraits_display_override(portrait_parent: Node, character_name: String = "") -> void:
	if character_name == "":
		_portraits_display_override = portrait_parent
	else:
		_portraits_display_per_character[character_name] = portrait_parent


## Set the parent node where the dialog box will be displayed for a given character.
## If no character name is provided, it sets the default overrided parent node
## for all characters (If is set, otherwise it returns null).
func set_dialog_box_display_override(dialog_box_parent: Node, character_name: String = "") -> void:
	if character_name == "":
		_dialog_box_display_override = dialog_box_parent
	else:
		_dialog_box_display_per_character[character_name] = dialog_box_parent


## Set the dialog box node to be used for a given character.
## If no character name is provided, it sets the default overrided dialog box
## node for all characters (If is set, otherwise it returns null).
## [br][br]If the [code]ignore_display_override[/code] flag is set to [code]true[/code], 
## the dialog box will be used as is, without changing its parent node.
func set_dialog_box_override(
		dialog_box: DialogBox,
		ignore_display_override: bool = false,
		character_name: String = "",
	) -> void:
	if character_name == "":
		_dialog_box_override = dialog_box
		_ignore_dialog_box_display_override = ignore_display_override
	else:
		_dialog_box_override_per_character[character_name]["dialog_box"] = dialog_box
		_dialog_box_override_per_character[character_name]["ignore_display_override"] = ignore_display_override


## Set the dialogue data and start ID to play a dialog tree.
## This method loads the dialog resources and prepares the player to process
## the dialog tree before calling the [method start] method.
func set_dialog(data: SproutyDialogsDialogueData, start_id: String,
		portrait_parents: Dictionary = {}, dialog_box_parents: Dictionary = {}) -> void:
	if not data:
		printerr("[Sprouty Dialogs] No dialogue data provided to set.")
		return
	if not _runner and not Engine.is_editor_hint():
		_create_runner()
	_dialog_data = data
	_start_id = start_id

	if not _starts_ids.has(_start_id): # Check if the dialog with given id exists
		printerr("[Sprouty Dialogs] Cannot find'" + _start_id + "'ID on dialogue data.")
		_start_id = "(Select a dialog)"
		_dialog_data = null
		if _runner:
			_runner.clear_dialog()
		return

	if not portrait_parents.is_empty():
		_portraits_display_per_character = portrait_parents
	if not dialog_box_parents.is_empty():
		_dialog_box_display_per_character = dialog_box_parents

	if _runner:
		_runner.set_dialog(data, start_id)


## Set the override dictionaries for portraits and dialog boxes per character.
func _set_overrides_dictionaries() -> void:
	if not _dialog_data or not _starts_ids.has(_start_id):
		return
	for char in _dialog_data.characters[_start_id]:
		if not _portraits_display_per_character.has(char):
			_portraits_display_per_character[char] = null
		if not _dialog_box_display_per_character.has(char):
			_dialog_box_display_per_character[char] = null
		if not _dialog_box_override_per_character.has(char):
			_dialog_box_override_per_character[char] = {
				"dialog_box": null,
				"ignore_display_override": false
			}


#region === Run dialog =========================================================

## Plays the dialog tree.
## [br][br]Need to set the [member _dialog_data] and [member _start_id] before calling this method. 
## The resources are loaded on the [method _ready] method.
##
## [br][br]It's the same as [method start].[br][br]
## [i](This was added to follow the Godot conventions, without breaking existing API).
func play() -> void:
	start()


## Start processing the dialog tree.
## [br][br]Need to set the [member _dialog_data] and [member _start_id] before calling this method.
## The resources are loaded on the [method _ready] method.[br][br]
##
## @deprecated: Use [method play] instead.
func start() -> void:
	if not _runner:
		printerr("[Sprouty Dialogs] No runner available to play the dialogue.")
		return
	if not _runner.get_dialog_data():
		_runner.set_dialog(_dialog_data, _start_id)
	_runner.play()


## Pause processing the dialog tree
func pause() -> void:
	if not _runner:
		return
	_runner.pause()


## Resume processing the dialog tree
func resume() -> void:
	if not _runner:
		return
	_runner.resume()


## Stop processing the dialog tree
func stop() -> void:
	if not _runner:
		return
	_runner.stop()


## Check if the dialog is running
func is_running() -> bool:
	if not _runner:
		return false
	return _runner.is_running()

#endregion

#region === Process graph ======================================================

## Play dialog when the dialogue node is processed
func _on_dialogue_processed(character_name: String, translated_name: String,
		portrait: String, dialog_data: Dictionary) -> void:
	_update_dialog_box(character_name)
	_set_dialog_box_from_tag_data(_current_dialog_box, dialog_data)

	if character_name.is_empty():
		_current_dialog_box.play_dialog(translated_name, dialog_data)
		return

	var is_joining = _change_current_portrait(character_name, portrait)
	var character_data = get_character_data(character_name)
	if character_data and character_data.portrait_on_dialog_box:
		_current_dialog_box.play_dialog(translated_name, dialog_data)
		await _update_portrait(character_name, is_joining)
	else:
		await _update_portrait(character_name, is_joining)
		_current_dialog_box.play_dialog(translated_name, dialog_data)


## Handle when the options node is processed
func _on_options_processed(options: Array, disabled_flags: Array) -> void:
	if not _current_dialog_box:
		_update_dialog_box("") # Use default dialog box

	if _current_dialog_box:
		_current_dialog_box.display_options(options, disabled_flags)


## Process the next node of the option selected
func _on_option_selected(option_index: int) -> void:
	if _current_dialog_box:
		_current_dialog_box.hide_options()
	if _runner:
		_runner.select_option(option_index)


## Continue to the next node in the dialog tree
func _on_continue_dialog() -> void:
	if _runner:
		_runner.continue_dialogue()


## Handle when the dialog is paused
func _on_dialog_paused() -> void:
	# If there is a current dialog box, pause it
	if _current_dialog_box:
		_current_dialog_box.pause_dialog()
		if _current_portrait and _current_portrait.get_parent():
			_current_portrait.on_portrait_stop_talking()
	dialog_paused.emit()


## Handle when the dialog is resumed
func _on_dialog_resumed() -> void:
	# If there is a current dialog box, resume it
	if _current_dialog_box:
		_current_dialog_box.resume_dialog()
		if _current_portrait and _current_portrait.get_parent():
			_current_portrait.on_portrait_talk()
	dialog_resumed.emit()


## Handle when the dialog ends
func _on_dialog_ended() -> void:
	if print_debug: print("[Sprouty Dialogs] Dialog ended.")
	_current_portrait = null

	# Exit all active portraits
	for char in _portraits_instances.keys():
		for portrait in _portraits_instances[char].values():
			if portrait and portrait.is_visible() and portrait.get_parent():
				await portrait.on_portrait_exit()

	# If there is a visible dialog box, stop it
	if _current_dialog_box:
		await _current_dialog_box.stop_dialog(true)
		_current_dialog_box = null

	# Free all portraits displayed
	for char in _portraits_instances.keys():
		for portrait in _portraits_instances[char].values():
			if portrait: # Remove the character node with the portraits
				var portrait_parent = portrait.get_parent()
				if portrait_parent and portrait_parent.get_parent():
					portrait_parent.get_parent().remove_child(portrait_parent)
					portrait_parent.queue_free()

	# Free all dialog boxes displayed
	for char in _dialog_box_instances.keys():
		var dialog_box = _dialog_box_instances[char]
		if _dialog_box_override == dialog_box:
			continue # If dialog box is an override, don't free it
		if _dialog_box_override_per_character.has(char) and \
				_dialog_box_override_per_character[char]["dialog_box"] == dialog_box:
			continue # If dialog box is an override, don't free it
		dialog_box.queue_free()

	_portraits_instances.clear()
	_dialog_box_instances.clear()

	dialog_ended.emit()
	dialog_player_stop.emit()

	if _destroy_on_end:
		queue_free()

#endregion

#region === Dialog box and portrait management =================================

## Update the dialog box for the current character
func _update_dialog_box(character_name: String) -> void:
	var dialog_box = null

	# If the character already has a dialog box instance, use it
	if _dialog_box_instances.has(character_name):
		dialog_box = _dialog_box_instances[character_name]
	else:
		# If the character has a display parent override, use it
		var display_parent = _dialog_box_display_per_character.get(character_name, null)
		if not display_parent: display_parent = _dialog_box_display_override

		# Instantiate the dialog box if it is not already loaded
		dialog_box = _resource_manager.instantiate_dialog_box(
			character_name, display_parent, _dialog_box_override,
			_ignore_dialog_box_display_override,
			_dialog_box_override_per_character.get(character_name, {
					"dialog_box": null,
					"ignore_display_override": false
				})
			)
		if not dialog_box:
			# Try to use the default dialog box if the one of the character
			# could not be instantiated (e.g. invalid character reference)
			dialog_box = _resource_manager.instantiate_dialog_box(
					"", display_parent, _dialog_box_override,
					_ignore_dialog_box_display_override, {})
		if not dialog_box:
			printerr("[Sprouty Dialogs] Cannot create a dialog box to run the dialogue.")
			return
		dialog_box.set_auto_advance(auto_advance)
		dialog_box.text_reveal_skippable = text_reveal_skippable
		_dialog_box_instances[character_name] = dialog_box
	
	# Check if the dialog box is already playing a dialog
	if _current_dialog_box and dialog_box != _current_dialog_box:
		_current_dialog_box.stop_dialog() # End the current dialog

	# Connect the dialog box signals
	if not dialog_box.is_connected("continue_dialog", _on_continue_dialog):
		dialog_box.continue_dialog.connect(_on_continue_dialog)
		dialog_box.dialog_typing_starts.connect(_on_dialog_typing_starts)
		dialog_box.dialog_typing_ends.connect(_on_dialog_typing_ends)
		dialog_box.dialog_starts.connect(_on_dialog_display_starts)
		dialog_box.dialog_ends.connect(_on_dialog_display_ends)
		dialog_box.option_selected.connect(_on_option_selected)
	
	_current_dialog_box = dialog_box


## Set dialog box settings from tag data
func _set_dialog_box_from_tag_data(dialog_box: DialogBox, dialog_data: Dictionary) -> void:
	var auto_delay = null
	if not dialog_data.is_empty():
		# Auto-advance settings
		if dialog_data.has("auto"):
			var auto_data = dialog_data["auto"]
			auto_advance = auto_data.get("enabled", true)
			auto_delay = auto_data.get("delay", null)
		# No skip text reveal settings
		if dialog_data.has("noskip"):
			if dialog_data["noskip"] == false: # If the dialog data allows skipping, check the global setting
				var text_reveal_skippable_enabled = SproutyDialogsSettingsManager.get_setting("allow_skip_text_reveal")
				if text_reveal_skippable_enabled != null:
					text_reveal_skippable = text_reveal_skippable_enabled
			else:
				text_reveal_skippable = not dialog_data["noskip"]
	
	# Update the dialog box settings
	if auto_delay == null:
		dialog_box.set_auto_advance(auto_advance)
	else:
		dialog_box.set_auto_advance(auto_advance, auto_delay)
	dialog_box.text_reveal_skippable = text_reveal_skippable


## Change the current portrait for the character.
func _change_current_portrait(character_name: String, portrait_name: String) -> bool:
	if character_name.is_empty() or portrait_name.is_empty():
		_current_portrait = null
		return false

	var is_joining = false
	# Check if the character is joining the dialog
	if not _portraits_instances.has(character_name):
		_portraits_instances[character_name] = {}
		is_joining = true
	
	# If the portrait is already loaded, use it
	if _portraits_instances[character_name].has(portrait_name):
		_current_portrait = _portraits_instances[character_name][portrait_name]

	else: # Instantiate the portrait scene if not already loaded
		var display_parent = _portraits_display_per_character.get(character_name, null)
		if not display_parent: display_parent = _portraits_display_override
		_current_portrait = _resource_manager.instantiate_portrait(
			character_name, portrait_name, display_parent, _current_dialog_box)
		_portraits_instances[character_name][portrait_name] = _current_portrait
	
	if _current_portrait:
		_current_portrait.set_portrait()
	
	return is_joining


## Update the portrait visibility and play entry animation (if needed).
func _update_portrait(character_name: String, is_joining: bool) -> void:
	# The character may have no portraits loaded when it has no portrait
	# (or no default portrait) set on its dialogue nodes
	if _portraits_instances.has(character_name):
		# Hide all other portraits of the character
		for portrait in _portraits_instances[character_name].values():
			if not portrait:
				continue
			if portrait != _current_portrait:
				portrait.hide()
			else:
				portrait.show()
	
	# Entry action if the character is joining the dialog
	if is_joining and _current_portrait and _current_portrait.get_parent():
		await _current_portrait.on_portrait_enter()


## Handle when the dialog display starts for a character.
func _on_dialog_display_starts() -> void:
	pass


## Handle when the dialog typing starts for a character.
func _on_dialog_typing_starts() -> void:
	if _current_portrait and _current_portrait.get_parent():
		_current_portrait.on_portrait_talk()


## Handle when the dialog display ends for a character.
func _on_dialog_display_ends() -> void:
	if _current_portrait and _current_portrait.get_parent():
		_current_portrait.unhighlight_portrait()


## Handle when the dialog typing ends for a character.
func _on_dialog_typing_ends() -> void:
	if _current_portrait and _current_portrait.get_parent():
		_current_portrait.on_portrait_stop_talking()

#endregion

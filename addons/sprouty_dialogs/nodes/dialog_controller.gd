@icon("res://addons/sprouty_dialogs/editor/icons/nodes/dialog_controller.svg")
class_name DialogController
extends Node

# -----------------------------------------------------------------------------
# Sprouty Dialogs Dialog Controller
# -----------------------------------------------------------------------------
## Node that runs dialog trees from Sprouty Dialogs plugin without any UI.
##
## It executes the dialogue and emits execution events for you to display the
## dialogues and options with your own UI. It does not create dialog boxes,
## portraits or handle input, so you must continue the dialogue and select the
## options manually.[br][br]
##
## Use [DialogPlayer] instead if you want the integrated dialog box and input
## handling.
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
		if _runner:
			_runner.print_debug = value

## Runner instance that executes the dialogue trees.
var _runner: SproutyDialogsRunner


func _enter_tree() -> void:
	_ensure_runner()


## Set the dialogue data and start ID to play a dialog tree.
## This method loads the dialog resources and prepares the controller to process
## the dialog tree before calling the [method play] method.
func set_dialog(dialog_data: Resource, start_id: String) -> void:
	_ensure_runner().set_dialog(dialog_data as SproutyDialogsDialogueData, start_id)


## Clear the current dialogue data and release its resources.
func clear_dialog() -> void:
	if _runner:
		_runner.clear_dialog()


## Plays the dialog tree.
func play() -> void:
	_ensure_runner().play()


## Continue to the next node after a dialogue was requested.
func continue_dialogue() -> void:
	_ensure_runner().continue_dialogue()


## Select an option after an options node was processed.
## The [param option_index] is the index of the selectable option, excluding
## the disabled options.
func select_option(option_index: int) -> void:
	_ensure_runner().select_option(option_index)


## Pause processing the dialog tree.
func pause() -> void:
	_ensure_runner().pause()


## Resume processing the dialog tree.
func resume() -> void:
	_ensure_runner().resume()


## Stop processing the dialog tree and release its resources.
func stop() -> void:
	_ensure_runner().stop()


## Check if the dialog is running.
func is_running() -> bool:
	if not _runner:
		return false
	return _runner.is_running()


## Returns the current node being processed.
func get_current_node() -> String:
	if not _runner:
		return ""
	return _runner.get_current_node()


## Returns the dialogue data resource being processed.
func get_dialog_data() -> SproutyDialogsDialogueData:
	if not _runner:
		return null
	return _runner.get_dialog_data()


## Returns the start ID of the dialog tree being processed.
func get_start_id() -> String:
	if not _runner:
		return ""
	return _runner.get_start_id()


## Returns character data for a given character key name.
func get_character_data(key_name: String) -> SproutyDialogsCharacterData:
	if _runner:
		return _runner.get_character_data(key_name)
	return null


## Create the runner that executes the dialogue trees and connect its signals.
func _ensure_runner() -> SproutyDialogsRunner:
	if _runner:
		return _runner
	_runner = SproutyDialogsRunner.new()
	_runner.name = "SproutyDialogsRunner"
	_runner.print_debug = print_debug
	_runner.dialog_started.connect(dialog_started.emit)
	_runner.dialogue_requested.connect(dialogue_requested.emit)
	_runner.options_requested.connect(options_requested.emit)
	_runner.dialog_paused.connect(dialog_paused.emit)
	_runner.dialog_resumed.connect(dialog_resumed.emit)
	_runner.dialog_ended.connect(dialog_ended.emit)
	_runner.option_selected.connect(option_selected.emit)
	_runner.signal_event.connect(signal_event.emit)
	add_child(_runner)
	return _runner

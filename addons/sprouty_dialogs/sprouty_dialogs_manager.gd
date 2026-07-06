class_name SproutyDialogsManager
extends Node

# -----------------------------------------------------------------------------
# Sprouty Dialogs Manager
# -----------------------------------------------------------------------------
## This class is used as the autoload that manages the Sprouty Dialogs plugin.
##
## Keep track of the running dialog players and dialog states by signals.
##
## Also, allows to start a dialog with the [method start_dialog] method directly
## from code, without needing to create a dialog player instance in the scene.
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

## The list of [DialogPlayer]s currently running.
## This is used to keep track of multiple [DialogPlayer]s running at the same time.
var dialog_players_running: Array[DialogPlayer] = []

## Resource manager singleton instance
var Resources := SproutyDialogsResourceManager.new()
## Variable manager singleton instance
var Variables := SproutyDialogsVariableManager.new()
## Settings manager reference
var Settings := SproutyDialogsSettingsManager


func _ready():
	# Make the manager available as a singleton
	if not Engine.has_singleton("SproutyDialogs"):
		Engine.register_singleton("SproutyDialogs", self)

	# Set managers instances
	Variables.name = "VariablesManager"
	Resources.name = "ResourcesManager"
	add_child(Variables)
	add_child(Resources)


#region === Play dialog ========================================================

## Play a dialog with the given data and start ID.
## [br]This will create a new [DialogPlayer] instance and play it.
##
## [br][br]This method also [b]loads all the resources needed for the dialogue at
## once[/b] when the method is called, [color=tomato][b]so may cause a slowdown if
## you have large resources to load.[/b][/color]
##
## [br][br]It's the same as [method start_dialog].[br][br]
## [i](This was added to follow the Godot conventions, without breaking existing API).
func play(data: SproutyDialogsDialogueData, start_id: String,
		portrait_parents: Dictionary = {}, dialog_box_parents: Dictionary = {}) -> DialogPlayer:
	return start_dialog(data, start_id, portrait_parents, dialog_box_parents)


## Start a dialog with the given data and start ID.
## [br]This will create a new [DialogPlayer] instance and play it.
##
## [br][br]This method also [b]loads all the resources needed for the dialogue at
## once[/b] when the method is called, [color=tomato][b]so may cause a slowdown if
## you have large resources to load.[/b][/color]
##
## @deprecated: Use [method play] instead.
func start_dialog(data: SproutyDialogsDialogueData, start_id: String,
		portrait_parents: Dictionary = {}, dialog_box_parents: Dictionary = {}) -> DialogPlayer:
	# Create a new dialog player instance
	var new_dialog_player = DialogPlayer.new()
	new_dialog_player.free_on_end = true
	add_child(new_dialog_player)

	# Set the dialogue data and start running the dialog
	new_dialog_player.set_dialog(data, start_id, portrait_parents, dialog_box_parents)
	new_dialog_player.play()
	return new_dialog_player

#endregion

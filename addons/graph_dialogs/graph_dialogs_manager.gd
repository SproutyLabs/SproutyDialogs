class_name GraphDialogsManager
extends Node

# -----------------------------------------------------------------------------
## Graph Dialogs Manager
##
## This is an autoload singleton that manages the Graph Dialogs plugin.
# -----------------------------------------------------------------------------

## Emitted when the dialog starts.
signal dialog_started(dialog_file: String, start_id: String)
## Emitted when the dialog is paused.
signal dialog_paused(dialog_file: String, start_id: String)
## Emitted when the dialog is resumed.
signal dialog_resumed(dialog_file: String, start_id: String)
## Emitted when the dialog is ended.
signal dialog_ended(dialog_file: String, start_id: String)

## The list of dialog players currently running.
## This is used to keep track of multiple dialog players running at the same time.
var _current_dialog_players: Array[DialogPlayer] = []
## The resource manager instance used to load resources for the dialogs.
var _resource_manager: GraphDialogsResourceManager = null


func _ready():
	# Make the manager available as a singleton
	if not Engine.has_singleton("GraphDialogs"):
		Engine.register_singleton("GraphDialogs", self)


## Returns the current dialog players instances running.
func get_running_dialog_players() -> Array[DialogPlayer]:
	return _current_dialog_players


## Sets a dialog player as running.
func set_dialog_player_as_running(player: DialogPlayer) -> void:
	player.dialog_player_stop.connect(_on_dialog_player_stop)
	player.dialog_started.connect(dialog_started.emit)
	player.dialog_paused.connect(dialog_paused.emit)
	player.dialog_resumed.connect(dialog_resumed.emit)
	player.dialog_ended.connect(dialog_ended.emit)
	_current_dialog_players.append(player)


## Returns the resource manager instance used to load resources for the dialogs
## in the current scene. If no resource manager is set, it will create a new one.
func get_resource_manager(current_root: Node) -> GraphDialogsResourceManager:
	if not _resource_manager:
		# Create a new resource manager instance if it doesn't exist
		_resource_manager = GraphDialogsResourceManager.new()
		_resource_manager.name = "GraphDialogsResources"
		current_root.add_child.call_deferred(_resource_manager)
	return _resource_manager

#region === Run dialog =========================================================

## Start a dialog with the given data and start ID.
## This will create a new dialog player instance and start it.
## Also, [b]will load the resources needed for the dialog, such as characters, 
## dialog boxes, and portraits, before starting the dialog player.[/b][br][br]
##
## [color=red][b]This may cause a slowdown if resources are large.[/b][/color]
## It is recommended to start the dialog from a [DialogPlayer] instance, 
## instead of calling this method from here.
func start_dialog(data: GraphDialogsDialogueData, start_id: String) -> DialogPlayer:
	# Create a new dialog player instance
	var new_dialog_player = DialogPlayer.new()
	set_dialog_player_as_running(new_dialog_player)
	new_dialog_player.destroy_on_end(true)
	add_child(new_dialog_player)

	# Set the dialog data and start running the dialog
	new_dialog_player.set_dialog_data(data, start_id)
	new_dialog_player.start()
	return new_dialog_player


## Handle the dialog ended signal from the dialog player.
func _on_dialog_player_stop(dialog_player: DialogPlayer) -> void:
	_current_dialog_players.erase(dialog_player)

#endregion
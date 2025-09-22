extends Control

# -----------------------------------------------------------------------------
## Test scene for playing a dialog
##
## This scene is used to test the dialog system in isolation.
## It loads a dialog and starts playing it automatically.
# -----------------------------------------------------------------------------

func _ready() -> void:
	var autoload = get_node("/root/GraphDialogs")
	var dialog_path = GraphDialogsSettings.get_setting("play_dialog_path")
	var start_id = GraphDialogsSettings.get_setting("play_start_id")

	print("[Graph Dialogs] Playing dialog test scene...")
	autoload.start_dialog(load(dialog_path), start_id)
	autoload.dialog_ended.connect(get_tree().quit.unbind(2)) # Quit when done

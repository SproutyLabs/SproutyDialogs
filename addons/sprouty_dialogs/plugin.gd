@tool
extends EditorPlugin

const AUTOLOAD_NAME := "SproutyDialogs"
const PLUGIN_ICON_PATH := "res://addons/sprouty_dialogs/editor/icons/plugin_icon.svg"
const PLUGIN_MANAGER_PATH := "res://addons/sprouty_dialogs/sprouty_dialogs_manager.gd"

const EDITOR_MAIN = preload("res://addons/sprouty_dialogs/editor/editor.tscn")

var editor: Control


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, PLUGIN_MANAGER_PATH)
	add_dialogs_input_actions()

	# Initialize the default settings if they don't exist.
	if not ProjectSettings.has_setting("graph_dialogs/variables/variables"):
		SproutyDialogsSettingsManager.initialize_default_settings()


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)


func _enter_tree():
	editor = EDITOR_MAIN.instantiate()

	# Get undo redo manager
	editor.undo_redo = get_undo_redo()

	# Add the main panel to the editor"s main viewport.
	EditorInterface.get_editor_main_screen().add_child(editor)
	_make_visible(false) # Hide the main panel initially.


func _exit_tree():
	if editor:
		editor.queue_free()


func _has_main_screen():
	return true


func _make_visible(visible):
	if editor:
		editor.visible = visible


func _get_plugin_name():
	return "Dialogs"


func _get_plugin_icon():
	return preload(PLUGIN_ICON_PATH)


func _handles(object: Object) -> bool:
	if object is SproutyDialogsDialogueData or object is SproutyDialogsCharacterData:
		if is_instance_valid(editor.file_manager):
			editor.file_manager.load_file(object.resource_path)
			return true
	return false


## Adds the default dialogs input actions to the project settings if it doesn't exist.
func add_dialogs_input_actions() -> void:
	if not ProjectSettings.has_setting("input/dialogs_continue_action"):
		var input_enter: InputEventKey = InputEventKey.new()
		input_enter.keycode = KEY_ENTER
		var input_space: InputEventKey = InputEventKey.new()
		input_space.keycode = KEY_SPACE
		var input_mouse: InputEventMouseButton = InputEventMouseButton.new()
		input_mouse.button_index = MOUSE_BUTTON_LEFT
		input_mouse.pressed = true
		var input_controller: InputEventJoypadButton = InputEventJoypadButton.new()
		input_controller.button_index = JOY_BUTTON_B

		ProjectSettings.set_setting("input/dialogs_continue_action", {
			"deadzone": 0.5,
			"events": [input_enter, input_space, input_mouse, input_controller]
		})
		ProjectSettings.save()

@tool
extends EditorPlugin

const MAIN_PANEL = preload("res://addons/graph_dialogs/editor/editor.tscn")
const PLUGIN_NAME := "GraphDialogs"
const PLUGIN_ICON_PATH := "res://addons/graph_dialogs/icons/icon.svg"
const PLUGIN_MANAGER_PATH := "res://addons/graph_dialogs/graph_dialogs_manager.gd"

var main_panel_instance


func _enable_plugin() -> void:
	add_autoload_singleton(PLUGIN_NAME, PLUGIN_MANAGER_PATH)
	add_dialogs_input_actions()
	
	# Initialize the default settings if they don't exist.
	if not ProjectSettings.has_setting("graph_dialogs/general/default_dialog_box"):
		GraphDialogsSettings.initialize_default_settings()


func _disable_plugin() -> void:
	remove_autoload_singleton(PLUGIN_NAME)


func _enter_tree():
	main_panel_instance = MAIN_PANEL.instantiate()

	# Add the main panel to the editor"s main viewport.
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	_make_visible(false) # Hide the main panel. Very much required.


func _exit_tree():
	if main_panel_instance:
		main_panel_instance.queue_free()


func _has_main_screen():
	return true


func _make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible


func _get_plugin_name():
	return PLUGIN_NAME


func _get_plugin_icon():
	return preload(PLUGIN_ICON_PATH)


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
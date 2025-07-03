@tool
extends EditorPlugin

const MAIN_PANEL = preload("res://addons/graph_dialogs/editor/editor.tscn")
const PLUGIN_NAME := "GraphDialogs"
const PLUGIN_ICON_PATH := "res://addons/graph_dialogs/icons/icon.svg"
const PLUGIN_MANAGER_PATH := "res://addons/graph_dialogs/graph_dialogs_manager.gd"

var main_panel_instance


func _enable_plugin() -> void:
	add_autoload_singleton(PLUGIN_NAME, PLUGIN_MANAGER_PATH)


func _disable_plugin() -> void:
	remove_autoload_singleton(PLUGIN_NAME)


func _enter_tree():
	main_panel_instance = MAIN_PANEL.instantiate()

	# Add the main panel to the editor's main viewport.
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

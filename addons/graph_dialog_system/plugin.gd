@tool
extends EditorPlugin

const MainPanel = preload("res://addons/graph_dialog_system/editor/editor.tscn")

var main_panel_instance

func _enter_tree():
	main_panel_instance = MainPanel.instantiate()

	# Add the main panel to the editor's main viewport.
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	_set_editor_resources_picker(main_panel_instance)
	_make_visible(false) # Hide the main panel. Very much required.

func _set_editor_resources_picker(main_panel) -> void:
	var objectField = EditorResourcePicker.new()
	objectField.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Resources fields
	objectField.base_type = "Texture2D"
	main_panel.get_node("%CharactersPanel/%PortraitField/Container").add_child(objectField)

func _exit_tree():
	if main_panel_instance:
		main_panel_instance.queue_free()


func _has_main_screen():
	return true


func _make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible


func _get_plugin_name(): # PLugin name on tabs
	return "GraphDialogs"


func _get_plugin_icon():
	# Must return some kind of Texture for the icon.
	return preload("res://addons/graph_dialog_system/icons/icon.svg")

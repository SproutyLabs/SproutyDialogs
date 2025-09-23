@tool
extends HSplitContainer

# -----------------------------------------------------------------------------
# General Settings
# -----------------------------------------------------------------------------
## This script handles the general settings panel in the Sprouty Dialogs editor.
## It allows to configure input actions, default scenes and canvas layers.
# -----------------------------------------------------------------------------

## Continue input action field
@onready var _continue_input_action_field: EditorSproutyDialogsComboBox = %ContinueInputActionField
## Default dialog box scene field
@onready var _default_dialog_box_field: EditorSproutyDialogsFileField = %DefaultDialogBoxField
## Default portrait scene field
@onready var _default_potrait_scene_field: EditorSproutyDialogsFileField = %DefaultPortraitSceneField
## Dialog box canvas layer field
@onready var _dialog_box_canvas_layer_field: SpinBox = %DialogBoxCanvasLayerField
## Portrait canvas layer field
@onready var _portrait_canvas_layer_field: SpinBox = %PortraitCanvasLayerField


func _ready():
	_continue_input_action_field.input_submitted.connect(_on_continue_input_action_changed)
	_default_dialog_box_field.file_path_submitted.connect(_on_default_dialog_box_path_changed)
	_default_potrait_scene_field.file_path_submitted.connect(_on_default_portrait_scene_path_changed)
	_dialog_box_canvas_layer_field.value_changed.connect(_on_dialog_box_canvas_layer_changed)
	_portrait_canvas_layer_field.value_changed.connect(_on_portrait_canvas_layer_changed)
	_continue_input_action_field.set_options(InputMap.get_actions().filter(
		func(action: String) -> bool: # Filter out built-in UI actions
			return (not action.begins_with("ui_")) and (not action.begins_with("spatial_editor"))
	))
	await get_tree().process_frame # Wait a frame to ensure settings are loaded
	_load_settings()


## Load settings and set the values in the UI
func _load_settings() -> void:
	_continue_input_action_field.set_value(
		EditorSproutyDialogsSettingsManager.get_setting("continue_input_action")
	)
	if EditorSproutyDialogsSettingsManager.get_setting("default_dialog_box") == -1:
		_default_dialog_box_field.set_value("")
	else:
		_default_dialog_box_field.set_value(ResourceUID.get_id_path(
				EditorSproutyDialogsSettingsManager.get_setting("default_dialog_box")
			)
		)
	if EditorSproutyDialogsSettingsManager.get_setting("default_portrait_scene") == -1:
		_default_potrait_scene_field.set_value("")
	else:
		_default_potrait_scene_field.set_value(ResourceUID.get_id_path(
				EditorSproutyDialogsSettingsManager.get_setting("default_portrait_scene")
			)
		)
	_dialog_box_canvas_layer_field.value = \
		EditorSproutyDialogsSettingsManager.get_setting("dialog_box_canvas_layer")
	_portrait_canvas_layer_field.value = \
		EditorSproutyDialogsSettingsManager.get_setting("portraits_canvas_layer")


## Handle when the continue input action is changed
func _on_continue_input_action_changed(new_value: String) -> void:
	EditorSproutyDialogsSettingsManager.set_setting("continue_input_action", new_value)


## Handle when the default dialog box path is changed
func _on_default_dialog_box_path_changed(new_path: String) -> void:
	EditorSproutyDialogsSettingsManager.set_setting("default_dialog_box",
			ResourceSaver.get_resource_id_for_path(new_path))


## Handle when the default portrait scene path is changed
func _on_default_portrait_scene_path_changed(new_path: String) -> void:
	EditorSproutyDialogsSettingsManager.set_setting("default_portrait_scene",
			ResourceSaver.get_resource_id_for_path(new_path))


## Handle when the dialog box canvas layer is changed
func _on_dialog_box_canvas_layer_changed(new_value: int) -> void:
	EditorSproutyDialogsSettingsManager.set_setting("dialog_box_canvas_layer", new_value)


## Handle when the portrait canvas layer is changed
func _on_portrait_canvas_layer_changed(new_value: int) -> void:
	EditorSproutyDialogsSettingsManager.set_setting("portraits_canvas_layer", new_value)
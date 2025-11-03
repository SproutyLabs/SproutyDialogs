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
## Warning labels for default portrait scene
@onready var _default_portrait_warning: RichTextLabel = %DefaultPortraitWarning
## Warning label for default dialog box
@onready var _default_dialog_box_warning: RichTextLabel = %DefaultDialogBoxWarning

## Dialog box canvas layer field
@onready var _dialog_box_canvas_layer_field: SpinBox = %DialogBoxCanvasLayerField
## Portrait canvas layer field
@onready var _portrait_canvas_layer_field: SpinBox = %PortraitCanvasLayerField


func _ready():
	_continue_input_action_field.input_submitted.connect(_on_continue_input_action_changed)
	_default_dialog_box_field.path_changed.connect(_on_default_dialog_box_path_changed)
	_default_potrait_scene_field.path_changed.connect(_on_default_portrait_scene_path_changed)
	_dialog_box_canvas_layer_field.value_changed.connect(_on_dialog_box_canvas_layer_changed)
	_portrait_canvas_layer_field.value_changed.connect(_on_portrait_canvas_layer_changed)
	_continue_input_action_field.set_options(InputMap.get_actions().filter(
		func(action: String) -> bool: # Filter out built-in UI actions
			return (not action.begins_with("ui_")) and (not action.begins_with("spatial_editor"))
	))
	_default_portrait_warning.visible = false
	_default_dialog_box_warning.visible = false

	await get_tree().process_frame # Wait a frame to ensure settings are loaded
	_load_settings()


## Load settings and set the values in the UI
func _load_settings() -> void:
	# Load the continue input action
	_continue_input_action_field.set_value(
		SproutyDialogsSettingsManager.get_setting("continue_input_action")
	)
	# Load the default dialog box
	var default_dialog_box = SproutyDialogsSettingsManager.get_setting("default_dialog_box")
	if not SproutyDialogsFileUtils.check_valid_uid_path(default_dialog_box):
		printerr("[Sprouty Dialogs] Default dialog box scene not found." \
				+" Check that the default dialog box is set in Settings > General" \
				+" plugin tab, and that the scene resource exists.")
		_default_dialog_box_warning.visible = true
		_default_dialog_box_field.set_value("")
	else:
		_default_dialog_box_warning.visible = false
		_default_dialog_box_field.set_value(ResourceUID.get_id_path(default_dialog_box))
	
	# Load the default portrait scene
	var default_portrait = SproutyDialogsSettingsManager.get_setting("default_portrait_scene")
	if not SproutyDialogsFileUtils.check_valid_uid_path(default_portrait):
		printerr("[Sprouty Dialogs] Default portrait scene not found." \
				+" Check that the default portrait scene is set in Settings > General" \
				+" plugin tab, and that the scene resource exists.")
		_default_portrait_warning.visible = true
		_default_potrait_scene_field.set_value("")
	else:
		_default_portrait_warning.visible = false
		_default_potrait_scene_field.set_value(ResourceUID.get_id_path(default_portrait))
	
	# Load Canvas layers settings
	_dialog_box_canvas_layer_field.value = \
		SproutyDialogsSettingsManager.get_setting("dialog_box_canvas_layer")
	_portrait_canvas_layer_field.value = \
		SproutyDialogsSettingsManager.get_setting("portraits_canvas_layer")


## Update settings when the panel is selected
func update_settings() -> void:
	_load_settings()


## Handle when the continue input action is changed
func _on_continue_input_action_changed(new_value: String) -> void:
	SproutyDialogsSettingsManager.set_setting("continue_input_action", new_value)


## Handle when the default dialog box path is changed
func _on_default_dialog_box_path_changed(new_path: String) -> void:
	if not ResourceLoader.exists(new_path) or \
			not SproutyDialogsFileUtils.check_valid_extension(new_path, ["*.tscn"]):
		_default_dialog_box_warning.visible = true
		return # Ignore empty or invalid paths
	_default_dialog_box_warning.visible = false
	SproutyDialogsSettingsManager.set_setting("default_dialog_box",
			ResourceSaver.get_resource_id_for_path(new_path, true))


## Handle when the default portrait scene path is changed
func _on_default_portrait_scene_path_changed(new_path: String) -> void:
	if not ResourceLoader.exists(new_path) or \
			not SproutyDialogsFileUtils.check_valid_extension(new_path, ["*.tscn"]):
		_default_portrait_warning.visible = true
		return # Ignore empty or invalid paths
	_default_portrait_warning.visible = false
	SproutyDialogsSettingsManager.set_setting("default_portrait_scene",
			ResourceSaver.get_resource_id_for_path(new_path, true))


## Handle when the dialog box canvas layer is changed
func _on_dialog_box_canvas_layer_changed(new_value: int) -> void:
	SproutyDialogsSettingsManager.set_setting("dialog_box_canvas_layer", new_value)


## Handle when the portrait canvas layer is changed
func _on_portrait_canvas_layer_changed(new_value: int) -> void:
	SproutyDialogsSettingsManager.set_setting("portraits_canvas_layer", new_value)
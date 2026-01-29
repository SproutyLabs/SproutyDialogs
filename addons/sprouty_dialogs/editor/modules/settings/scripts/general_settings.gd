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

## New dialog box button
@onready var _new_dialog_box_button: Button = %NewDialogBoxButton
## New portrait scene button
@onready var _new_portrait_scene_button: Button = %NewPortraitSceneButton
## New dialog box scene dialog
@onready var _new_dialog_box_dialog: FileDialog = $NewDialogBoxDialog
## New portrait scene dialog
@onready var _new_portrait_scene_dialog: FileDialog = $NewPortraitSceneDialog
## Dialog box scene button
@onready var _to_dialog_box_scene_button: Button = %ToDialogBoxSceneButton
## Portrait scene button
@onready var _to_portrait_scene_button: Button = %ToPortraitSceneButton

## Dialog box canvas layer field
@onready var _dialog_box_canvas_layer_field: SpinBox = %DialogBoxCanvasLayerField
## Portrait canvas layer field
@onready var _portrait_canvas_layer_field: SpinBox = %PortraitCanvasLayerField

## Use custom event nodes toggle
@onready var _use_custom_nodes_toggle: CheckButton = %UseCustomNodesToggle
## Custom event nodes folder field
@onready var _custom_nodes_folder_field: EditorSproutyDialogsFileField = %CustomNodesFolderField
## Custom event interpreter field
@onready var _custom_interpreter_field: EditorSproutyDialogsFileField = %CustomInterpreterField
## Custom event nodes folder warning
@onready var _custom_nodes_folder_warning: RichTextLabel = %CustomNodesFolderWarning
## Custom event nodes interpreter warning
@onready var _custom_interpreter_warning: RichTextLabel = %CustomInterpreterWarning


func _ready():
	_continue_input_action_field.input_changed.connect(_on_continue_input_action_changed)
	_default_dialog_box_field.path_changed.connect(_on_default_dialog_box_path_changed)
	_default_potrait_scene_field.path_changed.connect(_on_default_portrait_scene_path_changed)
	_dialog_box_canvas_layer_field.value_changed.connect(_on_dialog_box_canvas_layer_changed)
	_portrait_canvas_layer_field.value_changed.connect(_on_portrait_canvas_layer_changed)

	_to_dialog_box_scene_button.pressed.connect(_on_dialog_box_scene_button_pressed)
	_to_portrait_scene_button.pressed.connect(_on_portrait_scene_button_pressed)
	_new_portrait_scene_button.pressed.connect(_on_new_portrait_scene_pressed)
	_new_portrait_scene_dialog.file_selected.connect(_new_portrait_scene)
	_new_dialog_box_button.pressed.connect(_on_new_dialog_box_pressed)
	_new_dialog_box_dialog.file_selected.connect(_new_dialog_box)

	_use_custom_nodes_toggle.toggled.connect(_on_use_custom_nodes_toggled)
	_custom_nodes_folder_field.path_changed.connect(_on_custom_nodes_folder_path_changed)
	_custom_interpreter_field.path_changed.connect(_on_custom_interpreter_path_changed)

	_continue_input_action_field.set_options(InputMap.get_actions().filter(
		func(action: String) -> bool: # Filter out built-in UI actions
			return (not action.begins_with("ui_")) and (not action.begins_with("spatial_editor"))
	))
	_to_dialog_box_scene_button.icon = get_theme_icon("PackedScene", "EditorIcons")
	_to_portrait_scene_button.icon = get_theme_icon("PackedScene", "EditorIcons")
	_new_dialog_box_button.icon = get_theme_icon("Add", "EditorIcons")
	_new_portrait_scene_button.icon = get_theme_icon("Add", "EditorIcons")

	_default_dialog_box_warning.hide()
	_default_portrait_warning.hide()
	_custom_nodes_folder_warning.hide()
	_custom_interpreter_warning.hide()

	await get_tree().process_frame # Wait a frame to ensure settings are loaded
	_load_settings()


## Update settings when the panel is selected
func update_settings() -> void:
	if _custom_nodes_folder_warning.visible: # Reset path
		_custom_nodes_folder_field.set_value(_get_saved_setting("custom_event_nodes_folder"))
		_show_reset_button(_custom_nodes_folder_field, "custom_event_nodes_folder")
		_custom_nodes_folder_warning.hide()

	if _custom_interpreter_warning.visible: # Reset path
		_custom_interpreter_field.set_value(_get_saved_setting("custom_event_interpreter"))
		_show_reset_button(_custom_interpreter_field, "custom_event_interpreter")
		_custom_interpreter_warning.hide()


## Load settings and set the values in the UI
func _load_settings() -> void:
	# Load the continue input action
	_continue_input_action_field.set_value(
		SproutyDialogsSettingsManager.get_setting("continue_input_action")
	)
	_set_reset_button(_continue_input_action_field, "continue_input_action")

	# Load the default dialog box
	var default_dialog_box = SproutyDialogsSettingsManager.get_setting("default_dialog_box")
	if not SproutyDialogsFileUtils.check_valid_uid_path(default_dialog_box):
		printerr("[Sprouty Dialogs] Default dialog box scene not found." \
				+" Check that the default dialog box is set in Settings > General" \
				+" plugin tab, and that the scene resource exists.")
		_default_dialog_box_warning.show()
		_default_dialog_box_field.set_value("")
		_to_dialog_box_scene_button.hide()
		_new_dialog_box_button.show()
	else:
		_new_dialog_box_button.hide()
		_to_dialog_box_scene_button.show()
		_default_dialog_box_warning.hide()
		_default_dialog_box_field.set_value(ResourceUID.get_id_path(default_dialog_box))
	_set_reset_button(_default_dialog_box_field, "default_dialog_box")
	
	# Load the default portrait scene
	var default_portrait = SproutyDialogsSettingsManager.get_setting("default_portrait_scene")
	if not SproutyDialogsFileUtils.check_valid_uid_path(default_portrait):
		printerr("[Sprouty Dialogs] Default portrait scene not found." \
				+" Check that the default portrait scene is set in Settings > General" \
				+" plugin tab, and that the scene resource exists.")
		_default_portrait_warning.show()
		_default_potrait_scene_field.set_value("")
		_to_portrait_scene_button.hide()
		_new_portrait_scene_button.show()
	else:
		_new_portrait_scene_button.hide()
		_to_portrait_scene_button.show()
		_default_portrait_warning.hide()
		_default_potrait_scene_field.set_value(ResourceUID.get_id_path(default_portrait))
	_set_reset_button(_default_potrait_scene_field, "default_portrait_scene")
	
	# Load Canvas layers settings
	_dialog_box_canvas_layer_field.value = \
		SproutyDialogsSettingsManager.get_setting("dialog_box_canvas_layer")
	_set_reset_button(_dialog_box_canvas_layer_field, "dialog_box_canvas_layer")

	_portrait_canvas_layer_field.value = \
		SproutyDialogsSettingsManager.get_setting("portraits_canvas_layer")
	_set_reset_button(_portrait_canvas_layer_field, "portraits_canvas_layer")

	# Load custom settings
	_use_custom_nodes_toggle.button_pressed = \
			SproutyDialogsSettingsManager.get_setting("use_custom_event_nodes")
	_set_reset_button(_use_custom_nodes_toggle, "use_custom_event_nodes")

	# Load custom event nodes folder
	var custom_nodes_folder = SproutyDialogsSettingsManager.get_setting("custom_event_nodes_folder")
	if not DirAccess.dir_exists_absolute(custom_nodes_folder):
		if _use_custom_nodes_toggle.button_pressed:
			printerr("[Sprouty Dialogs] Custom event nodes folder not found." \
					+" Check that the folder path is set in Settings > General" \
					+" plugin tab, and that the directory exists.")
			_custom_nodes_folder_warning.show()
		_custom_nodes_folder_field.set_value("")
	else:
		_custom_nodes_folder_warning.hide()
		_custom_nodes_folder_field.set_value(custom_nodes_folder)
	_set_reset_button(_custom_nodes_folder_field, "custom_event_nodes_folder")

	# Load custom event nodes interpreter
	var custom_interpreter = SproutyDialogsSettingsManager.get_setting("custom_event_interpreter")
	if not SproutyDialogsFileUtils.check_valid_uid_path(custom_interpreter):
		if _use_custom_nodes_toggle.button_pressed:
			printerr("[Sprouty Dialogs] Custom event nodes interpreter not found." \
				+" Check that the script is set in Settings > General" \
				+" plugin tab, and that the file exists.")
			_custom_interpreter_warning.show()
		_custom_interpreter_field.set_value("")
	else:
		_custom_interpreter_warning.hide()
		_custom_interpreter_field.set_value(ResourceUID.get_id_path(custom_interpreter))
	_set_reset_button(_custom_interpreter_field, "custom_event_interpreter")


## Setup the reset button of a field
func _set_reset_button(field: Control, setting_name: String) -> void:
	var default_value = SproutyDialogsSettingsManager.get_default_setting(setting_name)
	var reset_button = field.get_parent().get_child(1)

	if field is EditorSproutyDialogsComboBox:
		reset_button.pressed.connect(func():
			SproutyDialogsSettingsManager.reset_setting(setting_name)
			field.set_value(default_value)
			reset_button.hide()
		)
		reset_button.visible = field.get_value() != default_value
	
	elif field is EditorSproutyDialogsFileField:
		# Use the previous saved settings instead of default
		reset_button.pressed.connect(func():
			reset_button.hide()
			# Hide fields warnings and handle scene buttons
			if setting_name.contains("dialog_box"):
				SproutyDialogsSettingsManager.reset_setting(setting_name)
				field.set_value(ResourceUID.get_id_path(default_value))
				_default_dialog_box_warning.hide()
				_new_dialog_box_button.hide()
				_to_dialog_box_scene_button.show()
			
			if setting_name.contains("portrait_scene"):
				SproutyDialogsSettingsManager.reset_setting(setting_name)
				field.set_value(ResourceUID.get_id_path(default_value))
				_default_portrait_warning.hide()
				_new_portrait_scene_button.hide()
				_to_portrait_scene_button.show()
			
			if setting_name == "custom_event_nodes_folder":
				field.set_value(_get_saved_setting(setting_name))
				_custom_nodes_folder_warning.hide()
			
			if setting_name == "custom_event_interpreter":
				field.set_value(_get_saved_setting(setting_name))
				_custom_interpreter_warning.hide()
		)
		reset_button.visible = field.get_value() != _get_saved_setting(setting_name)

	elif field is SpinBox:
		reset_button.pressed.connect(func():
			SproutyDialogsSettingsManager.reset_setting(setting_name)
			field.set_value_no_signal(default_value)
			reset_button.hide()
		)
		reset_button.visible = field.value != default_value
	
	elif field is CheckButton:
		reset_button.pressed.connect(func():
			SproutyDialogsSettingsManager.reset_setting(setting_name)
			field.set_pressed_no_signal(default_value)
			reset_button.hide()

			if setting_name.contains("use_custom"):
				_on_custom_nodes_folder_path_changed(_custom_nodes_folder_field.get_value())
				_on_custom_interpreter_path_changed(_custom_interpreter_field.get_value())
		)
		reset_button.visible = field.button_pressed != default_value


## Show the reset button of a field
func _show_reset_button(field: Control, setting_name: String) -> void:
	var default_value = SproutyDialogsSettingsManager.get_default_setting(setting_name)
	var reset_button = field.get_parent().get_child(1)

	if field is EditorSproutyDialogsComboBox:
		reset_button.visible = field.get_value() != default_value
	
	elif field is EditorSproutyDialogsFileField:
		reset_button.visible = field.get_value() != _get_saved_setting(setting_name)
	
	elif field is SpinBox:
		reset_button.visible = field.value != default_value
	
	elif field is CheckButton:
		reset_button.visible = field.button_pressed != default_value


## Get the previous saved setting value
func _get_saved_setting(setting_name: String) -> Variant:
	var setting_value = SproutyDialogsSettingsManager.get_setting(setting_name)
	if setting_value is int:
		if ResourceUID.has_id(setting_value):
			return ResourceUID.get_id_path(setting_value)
		else:
			return ""
	else:
		return setting_value


## Handle when the continue input action is changed
func _on_continue_input_action_changed(new_value: String) -> void:
	SproutyDialogsSettingsManager.set_setting("continue_input_action", new_value)
	_show_reset_button(_continue_input_action_field, "continue_input_action")


## Handle when the default dialog box path is changed
func _on_default_dialog_box_path_changed(new_path: String) -> void:
	_show_reset_button(_default_dialog_box_field, "default_dialog_box")
	_new_dialog_box_button.visible = new_path.is_empty()

	if not ResourceLoader.exists(new_path) or \
			not SproutyDialogsFileUtils.check_valid_extension(new_path, ["*.tscn"]):
		_default_dialog_box_warning.show()
		_to_dialog_box_scene_button.hide()
		return # Ignore empty or invalid paths
	
	_default_dialog_box_warning.hide()
	_to_dialog_box_scene_button.show()

	SproutyDialogsSettingsManager.set_setting("default_dialog_box",
			ResourceSaver.get_resource_id_for_path(new_path, true))


## Handle when the default portrait scene path is changed
func _on_default_portrait_scene_path_changed(new_path: String) -> void:
	_show_reset_button(_default_potrait_scene_field, "default_portrait_scene")
	_new_portrait_scene_button.visible = new_path.is_empty()

	if not ResourceLoader.exists(new_path) or \
			not SproutyDialogsFileUtils.check_valid_extension(new_path, ["*.tscn"]):
		_default_portrait_warning.show()
		_to_portrait_scene_button.hide()
		return # Ignore empty or invalid paths
	
	_default_portrait_warning.hide()
	_to_portrait_scene_button.show()

	SproutyDialogsSettingsManager.set_setting("default_portrait_scene",
			ResourceSaver.get_resource_id_for_path(new_path, true))


## Handle when the dialog box canvas layer is changed
func _on_dialog_box_canvas_layer_changed(new_value: int) -> void:
	SproutyDialogsSettingsManager.set_setting("dialog_box_canvas_layer", new_value)
	_show_reset_button(_dialog_box_canvas_layer_field, "dialog_box_canvas_layer")


## Handle when the portrait canvas layer is changed
func _on_portrait_canvas_layer_changed(new_value: int) -> void:
	SproutyDialogsSettingsManager.set_setting("portraits_canvas_layer", new_value)
	_show_reset_button(_portrait_canvas_layer_field, "portraits_canvas_layer")


## Create a new dialog box scene and open it in the editor
func _on_new_dialog_box_pressed() -> void:
	_new_dialog_box_dialog.set_current_dir(SproutyDialogsFileUtils.get_recent_file_path("dialog_box_files"))
	_new_dialog_box_dialog.get_line_edit().text = "new_dialog_box.tscn"
	_new_dialog_box_dialog.popup_centered()


func _on_new_portrait_scene_pressed() -> void:
	_new_portrait_scene_dialog.set_current_dir(SproutyDialogsFileUtils.get_recent_file_path("portrait_files"))
	_new_portrait_scene_dialog.get_line_edit().text = "new_portrait.tscn"
	_new_portrait_scene_dialog.popup_centered()


## Create a new dialog box scene file
func _new_dialog_box(scene_path: String) -> void:
	SproutyDialogsFileUtils.create_new_scene_file(scene_path, "dialog_box")

	# Set the dialog box scene path
	_default_dialog_box_field.set_value(scene_path)
	_on_default_dialog_box_path_changed(scene_path)

	# Open the new scene in the editor
	SproutyDialogsFileUtils.open_scene_in_editor(scene_path, get_tree())


## Create a new dialog box scene file
func _new_portrait_scene(scene_path: String) -> void:
	SproutyDialogsFileUtils.create_new_scene_file(scene_path, "portrait_scene")

	# Set the dialog box scene path
	_default_potrait_scene_field.set_value(scene_path)
	_on_default_portrait_scene_path_changed(scene_path)

	# Open the new scene in the editor
	SproutyDialogsFileUtils.open_scene_in_editor(scene_path, get_tree())


## Handle the dialog box scene button press
func _on_dialog_box_scene_button_pressed() -> void:
	SproutyDialogsFileUtils.open_scene_in_editor(
			_default_dialog_box_field.get_value(), get_tree())


## Handle the dialog box scene button press
func _on_portrait_scene_button_pressed() -> void:
	SproutyDialogsFileUtils.open_scene_in_editor(
			_default_potrait_scene_field.get_value(), get_tree())


## Handle when the use custom nodes toggle is changed
func _on_use_custom_nodes_toggled(toggled_on: bool) -> void:
	SproutyDialogsSettingsManager.set_setting("use_custom_event_nodes", toggled_on)
	_show_reset_button(_use_custom_nodes_toggle, "use_custom_event_nodes")

	_on_custom_nodes_folder_path_changed(_custom_nodes_folder_field.get_value())
	_on_custom_interpreter_path_changed(_custom_interpreter_field.get_value())


## Handle when the custom nodes folder path is changed
func _on_custom_nodes_folder_path_changed(new_path: String) -> void:
	_show_reset_button(_custom_nodes_folder_field, "custom_event_nodes_folder")
	# Check if the path is empty or doesn't exist
	if new_path.is_empty() or not DirAccess.dir_exists_absolute(new_path):
		_custom_nodes_folder_warning.visible = _use_custom_nodes_toggle.button_pressed
		return
	_custom_nodes_folder_warning.hide()
	SproutyDialogsSettingsManager.set_setting("custom_event_nodes_folder", new_path)


## Handle when the custom nodes interpreter path is changed
func _on_custom_interpreter_path_changed(new_path: String) -> void:
	_show_reset_button(_custom_interpreter_field, "custom_event_interpreter")
	# Check if the path is valid
	if SproutyDialogsFileUtils.check_valid_extension(new_path, ["*.gd"]) \
			and ResourceLoader.exists(new_path):
		if not load(new_path).new() is SproutyDialogsEventInterpreter:
			_custom_interpreter_warning.visible = _use_custom_nodes_toggle.button_pressed
			return
	else:
		_custom_interpreter_warning.visible = _use_custom_nodes_toggle.button_pressed
		return
	_custom_interpreter_warning.hide()
	SproutyDialogsSettingsManager.set_setting("custom_event_interpreter",
			ResourceSaver.get_resource_id_for_path(new_path, true))
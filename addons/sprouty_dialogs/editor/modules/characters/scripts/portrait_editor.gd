@tool
extends VBoxContainer

# -----------------------------------------------------------------------------
# Portrait Editor
# ----------------------------------------------------------------------------- 
## This module allows the user to edit a portrait for a character.
## It provides a preview of the portrait and allows the user to set
## various properties and settings.
# -----------------------------------------------------------------------------

## Emitted when the portrait is modified
signal modified(modified: bool)
## Emitted to request opening a scene in the editor
signal request_open_scene_in_editor(scene_path: String)

## Portrait name label
@onready var _portrait_name: Label = $Title/PortraitName
## Portrait preview pivot node
@onready var _preview_container: Control = %PreviewContainer

## Portrait scene path field
@onready var _portrait_scene_field: EditorSproutyDialogsFileField = %PortraitSceneField
## Button to go to the portrait scene
@onready var _to_portrait_scene_button: Button = %ToPortraitSceneButton
## Button to create a new portrait scene
@onready var _new_portrait_scene_button: Button = %NewPortraitSceneButton
## New portrait scene dialog
@onready var _new_portrait_scene_dialog: FileDialog = $NewPortraitSceneDialog

## Exported properties section
@onready var _portrait_export_properties: Container = %PortraitProperties
## Image settings section
@onready var _transform_settings_section: Container = %TransformSettings
## Portrait scale section
@onready var _portrait_scale_section: Container = %PortraitScale
## Portrait rotation and mirror section
@onready var _portrait_rotation_section: Container = %PortraitRotation
## Portrait offset section
@onready var _portrait_offset_section: Container = %PortraitOffset

## Path of the current portrait scene
var _portrait_scene_path: String = ""
## Current transform settings
var _transform_settings: Dictionary = {
	"scale": Vector2.ONE,
	"scale_lock_ratio": true,
	"offset": Vector2.ZERO,
	"rotation": 0.0,
	"mirror": false
}
## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready():
	_to_portrait_scene_button.button_down.connect(_on_to_portrait_scene_button_pressed)
	_new_portrait_scene_button.button_down.connect(_on_new_portrait_scene_button_pressed)
	_new_portrait_scene_dialog.file_selected.connect(_new_portrait_scene)
	_portrait_scene_field.path_changed.connect(_on_portrait_scene_path_changed)
	_portrait_export_properties.property_changed.connect(_on_export_property_changed)
	_portrait_export_properties.modified.connect(modified.emit)

	%ReloadSceneButton.icon = get_theme_icon("Reload", "EditorIcons")
	%PreviewPivot.texture = get_theme_icon("EditorPivot", "EditorIcons")
	_new_portrait_scene_button.icon = get_theme_icon("Add", "EditorIcons")
	_to_portrait_scene_button.icon = get_theme_icon("PackedScene", "EditorIcons")
	_portrait_scale_section.get_node("LockRatioButton").icon = get_theme_icon("Instance", "EditorIcons")

	_new_portrait_scene_button.visible = true
	_to_portrait_scene_button.visible = false
	
	await get_tree().process_frame # Wait a frame to ensure the UndoRedo is ready
	_portrait_export_properties.undo_redo = undo_redo


## Get the portrait data from the editor
func get_portrait_data() -> SproutyDialogsPortraitData:
	var data = SproutyDialogsPortraitData.new()

	data.portrait_scene_uid = ResourceSaver.get_resource_id_for_path(
				_portrait_scene_field.get_value(), true) \
		if _check_valid_portrait_scene(_portrait_scene_field.get_value()) else -1
	
	data.portrait_scene_path = _portrait_scene_field.get_value() \
		if _check_valid_portrait_scene(_portrait_scene_field.get_value()) else ""
	
	data.export_overrides = _portrait_export_properties.get_export_overrides()
	data.transform_settings = {
		"scale": Vector2(
			_portrait_scale_section.get_node("XField").value,
			_portrait_scale_section.get_node("YField").value
		),
		"scale_lock_ratio": _portrait_scale_section.get_node("LockRatioButton").button_pressed,
		"offset": Vector2(
			_portrait_offset_section.get_node("XField").value,
			_portrait_offset_section.get_node("YField").value
		),
		"rotation": _portrait_rotation_section.get_node("RotationField").value,
		"mirror": _portrait_rotation_section.get_node("MirrorCheckBox").button_pressed
	}
	data.typing_sound = {} # Typing sound is not implemented yet
	return data


## Load the portrait settings into the editor
func load_portrait_data(name: String, data: SproutyDialogsPortraitData) -> void:
	set_portrait_name(name)

	# Set the portrait scene
	if not SproutyDialogsFileUtils.check_valid_uid_path(data.portrait_scene_uid):
		if data.portrait_scene_uid != -1:
			printerr("[Sprouty Dialogs] Portrait scene not found for portrait '"
					+ name + "'. Check that the file '" + data.portrait_scene_path + "' exists.")
		_portrait_scene_field.set_value("")
		_to_portrait_scene_button.visible = false
		_new_portrait_scene_button.visible = true
		_switch_scene_preview("")
	else:
		_portrait_scene_path = ResourceUID.get_id_path(data.portrait_scene_uid)
		_portrait_scene_field.set_value(_portrait_scene_path)
	
	_portrait_export_properties.set_export_overrides(data.export_overrides)
	
	# Check if the scene file is valid and set the preview
	if SproutyDialogsFileUtils.check_valid_extension(
			_portrait_scene_field.get_value(), _portrait_scene_field.file_filters):
		_to_portrait_scene_button.visible = true
		_new_portrait_scene_button.visible = false
		if not _portrait_export_properties.undo_redo:
			_portrait_export_properties.undo_redo = undo_redo
		_switch_scene_preview(_portrait_scene_field.get_value())
	else:
		_to_portrait_scene_button.visible = false
		_new_portrait_scene_button.visible = true

	# Load image settings
	_portrait_scale_section.get_node("LockRatioButton").set_pressed_no_signal(
			data.transform_settings.scale_lock_ratio)
	_portrait_scale_section.get_node("XField").set_value_no_signal(data.transform_settings.scale.x)
	_portrait_scale_section.get_node("YField").set_value_no_signal(data.transform_settings.scale.y)

	_portrait_offset_section.get_node("XField").set_value_no_signal(data.transform_settings.offset.x)
	_portrait_offset_section.get_node("YField").set_value_no_signal(data.transform_settings.offset.y)

	_portrait_rotation_section.get_node("RotationField").set_value_no_signal(data.transform_settings.rotation)
	_portrait_rotation_section.get_node("MirrorCheckBox").set_pressed_no_signal(data.transform_settings.mirror)
	
	_transform_settings = data.transform_settings
	
	_update_preview_transform() # Update the preview image with the loaded settings


## Set the portrait name in the editor
func set_portrait_name(name: String) -> void:
	_portrait_name.text = name

#region === Portrait Preview ===================================================

## Update the preview scene with transform settings
func _update_preview_transform() -> void:
	_preview_container.scale = Vector2(
		_portrait_scale_section.get_node("XField").value,
		_portrait_scale_section.get_node("YField").value
		)
	_preview_container.position = Vector2(
		_portrait_offset_section.get_node("XField").value,
		_portrait_offset_section.get_node("YField").value
		)
	_preview_container.rotation_degrees = _portrait_rotation_section.get_node("RotationField").value
	
	if _portrait_rotation_section.get_node("MirrorCheckBox").button_pressed:
		_preview_container.scale.x *= -1


## Switch the portrait scene in the preview
func _switch_scene_preview(new_scene: String) -> void:
	# Remove the previous scene from the preview
	if _preview_container.get_child_count() > 0:
			_preview_container.remove_child(_preview_container.get_child(0))
	
	if new_scene == "": # No scene file selected, hide the exported properties
		_portrait_export_properties.visible = false
		return
	
	var scene = load(new_scene).instantiate()
	_preview_container.add_child(scene)
	_portrait_export_properties.load_exported_properties(scene)
	if _preview_container.get_child(0).has_method("set_portrait"):
			_preview_container.get_child(0).set_portrait() # Update the portrait preview


## Reload the current scene in the preview
func _on_reload_scene_button_pressed() -> void:
	if _portrait_scene_field.get_value() != "":
		_switch_scene_preview(_portrait_scene_field.get_value())
	else:
		printerr("[Sprouty Dialogs] No scene file selected.")
		return
	_update_preview_transform()

#endregion

#region === Portrait Scene =====================================================

## Check if a portrait scene path is valid
func _check_valid_portrait_scene(path: String, print_error: bool = true) -> bool:
	var is_valid = SproutyDialogsFileUtils.check_valid_extension(path,
			_portrait_scene_field.file_filters) and FileAccess.file_exists(path)
	
	if is_valid: # Check if the scene inherits from DialogPortrait class
		var scene = load(path).instantiate()
		if not scene is DialogPortrait:
			if print_error:
				printerr("[Sprouty Dialogs] The scene '" + path + "' is not valid."
						+" The root node must inherit from DialogPortrait class.")
			is_valid = false
			scene.queue_free()
	
	return is_valid


## Update the portrait scene when the path changes
func _on_portrait_scene_path_changed(path: String) -> void:
	var is_valid = _check_valid_portrait_scene(path)

	# Update the visibility of the buttons
	_to_portrait_scene_button.visible = is_valid
	_new_portrait_scene_button.visible = not is_valid

	# Update the current portrait scene path and preview
	var temp = _portrait_scene_path
	_portrait_scene_path = path if is_valid else ""
	_switch_scene_preview(_portrait_scene_path)
	modified.emit(true)
	
	# --- UndoRedo --------------------------------------------------------
	undo_redo.create_action("Change Portrait Scene")
	undo_redo.add_do_method(_portrait_scene_field, "set_value", path)
	undo_redo.add_undo_method(_portrait_scene_field, "set_value", _portrait_scene_field.get_value())
	undo_redo.add_do_property(self, "_portrait_scene_path", path)
	undo_redo.add_undo_property(self, "_portrait_scene_path", temp)

	undo_redo.add_do_property(_to_portrait_scene_button, "visible", is_valid)
	undo_redo.add_undo_property(_to_portrait_scene_button, "visible",
		_check_valid_portrait_scene(temp, false))
	
	undo_redo.add_do_property(_new_portrait_scene_button, "visible", not is_valid)
	undo_redo.add_undo_property(_new_portrait_scene_button, "visible",
		not _check_valid_portrait_scene(temp, false))
	
	undo_redo.add_do_method(self, "_switch_scene_preview", _portrait_scene_path)
	undo_redo.add_undo_method(self, "_switch_scene_preview", temp)

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------------


## Select a path to create a new portrait scene file
func _on_new_portrait_scene_button_pressed() -> void:
	_new_portrait_scene_dialog.set_current_dir(SproutyDialogsFileUtils.get_recent_file_path("portrait_files"))
	_new_portrait_scene_dialog.get_line_edit().text = "new_portrait.tscn"
	_new_portrait_scene_dialog.popup_centered()


## Create a new portrait scene file
func _new_portrait_scene(scene_path: String) -> void:
	var default_uid = SproutyDialogsSettingsManager.get_setting("default_portrait_scene")
	var default_path = ""
	
	# If no default portrait scene is set or the resource does not exist, use the built-in default
	if not SproutyDialogsFileUtils.check_valid_uid_path(default_uid):
		printerr("[Sprouty Dialogs] No default portrait scene found." \
				+" Check that the default portrait scene is set in Settings > General" \
				+" plugin tab, and that the scene resource exists. Using built-in default instead.")
		default_path = SproutyDialogsSettingsManager.DEFAULT_PORTRAIT_PATH
		# Use and set the setting to the built-in default
		SproutyDialogsSettingsManager.set_setting("default_portrait_scene",
				ResourceSaver.get_resource_id_for_path(default_path, true))
	else: # Use the user-defined default portrait scene
		default_path = ResourceUID.get_id_path(default_uid)
	
	var new_scene = load(default_path).instantiate()
	new_scene.name = scene_path.get_file().split(".")[0].to_pascal_case()

	# Creates and set a template script for the new scene
	var script_path := scene_path.get_basename() + ".gd"
	var script = GDScript.new()
	script.source_code = new_scene.get_script().source_code
	ResourceSaver.save(script, script_path)
	new_scene.set_script(load(script_path))

	# Save the new scene file
	var packed_scene = PackedScene.new()
	packed_scene.pack(new_scene)
	ResourceSaver.save(packed_scene, scene_path)
	new_scene.queue_free()

	# Set the field and preview to the new scene file
	_portrait_scene_field.set_value(scene_path)
	_on_portrait_scene_path_changed(scene_path)

	# Open the new scene in the editor
	request_open_scene_in_editor.emit(scene_path)
	modified.emit(true)

	# Set the recent file path
	SproutyDialogsFileUtils.set_recent_file_path("portrait_files", scene_path)


## Open the portrait scene in the editor
func _on_to_portrait_scene_button_pressed() -> void:
	if _portrait_scene_field.get_value() != "":
		request_open_scene_in_editor.emit(_portrait_scene_field.get_value())
	else:
		printerr("[Sprouty Dialogs] No scene file selected.")

#endregion

#region === Transform Settings =================================================

## Set a transform setting in the dictionary
func _set_setting_on_dict(key: String, value: Variant) -> void:
	_transform_settings[key] = value


## Show or hide the image settings section
func _on_expand_transform_settings_toggled(toggled_on: bool) -> void:
	_transform_settings_section.visible = toggled_on


## Update the portrait scale lock ratio
func _on_scale_lock_ratio_toggled(toggled_on: bool) -> void:
	var temp = _transform_settings.scale_lock_ratio
	_transform_settings.scale_lock_ratio = toggled_on
	var lock_ratio_button = _portrait_scale_section.get_node("LockRatioButton")

	var scale_temp_x = _transform_settings.scale.x
	var scale_x_field = _portrait_scale_section.get_node("XField")
	var scale_y_field = _portrait_scale_section.get_node("YField")

	# Update the lock ratio button icon
	lock_ratio_button.icon = get_theme_icon("Instance", "EditorIcons") \
			if toggled_on else get_theme_icon("Unlinked", "EditorIcons")
	
	# If the ratio is locked, set Y scale to X scale
	if toggled_on and scale_x_field.value != scale_y_field.value:
		scale_y_field.set_value_no_signal(scale_x_field.value)
		_transform_settings.scale.y = scale_x_field.value
		_preview_container.scale.y = scale_x_field.value
	
	modified.emit(true)
	
	# --- UndoRedo --------------------------------------------------------
	undo_redo.create_action("Toggle Scale Lock Ratio")
	undo_redo.add_do_method(lock_ratio_button, "set_pressed_no_signal", toggled_on)
	undo_redo.add_undo_method(lock_ratio_button, "set_pressed_no_signal", temp)
	undo_redo.add_do_method(self, "_set_setting_on_dict", "scale_lock_ratio", toggled_on)
	undo_redo.add_undo_method(self, "_set_setting_on_dict", "scale_lock_ratio", temp)
	
	# Update the lock ratio button icon
	undo_redo.add_do_property(lock_ratio_button, "icon",
			get_theme_icon("Instance", "EditorIcons")
			if toggled_on else get_theme_icon("Unlinked", "EditorIcons"))
	undo_redo.add_undo_property(lock_ratio_button, "icon",
			get_theme_icon("Instance", "EditorIcons")
			if temp else get_theme_icon("Unlinked", "EditorIcons"))

	# If the ratio is locked, set Y scale to X scale
	if toggled_on and scale_x_field.value != scale_y_field.value:
		undo_redo.add_do_method(scale_y_field, "set_value_no_signal", scale_x_field.value)
		undo_redo.add_undo_method(scale_y_field, "set_value_no_signal", _transform_settings.scale.y)
		undo_redo.add_do_method(self, "_set_setting_on_dict", "scale",
				Vector2(scale_x_field.value, scale_x_field.value))
		undo_redo.add_undo_method(self, "_set_setting_on_dict", "scale", _transform_settings.scale)

		undo_redo.add_do_method(self, "_update_preview_transform")
		undo_redo.add_undo_method(self, "_update_preview_transform")
	
	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------------


## Update the portrait scale X value
func _on_scale_x_value_changed(value: float) -> void:
	var temp = _transform_settings.scale
	_transform_settings.scale.x = value
	var scale_x_field = _portrait_scale_section.get_node("XField")
	var scale_y_field = _portrait_scale_section.get_node("YField")
	
	# Update the Y scale if the ratio is locked
	if _portrait_scale_section.get_node("LockRatioButton").button_pressed:
		scale_y_field.set_value_no_signal(value)
		_transform_settings.scale.y = value
		_preview_container.scale.y = value
	
	_preview_container.scale.x = value
	modified.emit(true)

	# --- UndoRedo --------------------------------------------------------
	undo_redo.create_action("Change Portrait Scale X")
	undo_redo.add_do_method(scale_x_field, "set_value_no_signal", value)
	undo_redo.add_undo_method(scale_x_field, "set_value_no_signal", temp.x)

	if _portrait_scale_section.get_node("LockRatioButton").button_pressed:
		# Also change Y scale if ratio is locked
		undo_redo.add_do_method(scale_y_field, "set_value_no_signal", value)
		undo_redo.add_undo_method(scale_y_field, "set_value_no_signal", temp.y)
		undo_redo.add_do_method(self, "_set_setting_on_dict", "scale", Vector2(value, value))
	else: # Only change X scale
		undo_redo.add_do_method(self, "_set_setting_on_dict", "scale", Vector2(value, temp.y))
	undo_redo.add_undo_method(self, "_set_setting_on_dict", "scale", temp)

	undo_redo.add_do_method(self, "_update_preview_transform")
	undo_redo.add_undo_method(self, "_update_preview_transform")

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------------


## Update the portrait scale Y value
func _on_scale_y_value_changed(value: float) -> void:
	var temp = _transform_settings.scale
	_transform_settings.scale.y = value
	var scale_x_field = _portrait_scale_section.get_node("XField")
	var scale_y_field = _portrait_scale_section.get_node("YField")

	# Update the X scale if the ratio is locked
	if _portrait_scale_section.get_node("LockRatioButton").button_pressed:
		_portrait_scale_section.get_node("XField").value = value
		_transform_settings.scale.x = value
		_preview_container.scale.x = value
	
	_preview_container.scale.y = value
	modified.emit(true)

	# --- UndoRedo --------------------------------------------------------
	undo_redo.create_action("Change Portrait Scale Y")
	undo_redo.add_do_method(scale_y_field, "set_value_no_signal", value)
	undo_redo.add_undo_method(scale_y_field, "set_value_no_signal", temp.y)

	if _portrait_scale_section.get_node("LockRatioButton").button_pressed:
		# Also change X scale if ratio is locked
		undo_redo.add_do_method(scale_x_field, "set_value_no_signal", value)
		undo_redo.add_undo_method(scale_x_field, "set_value_no_signal", temp.x)
		undo_redo.add_do_method(self, "_set_setting_on_dict", "scale", Vector2(value, value))
	else: # Only change Y scale
		undo_redo.add_do_method(self, "_set_setting_on_dict", "scale", Vector2(temp.x, value))
	undo_redo.add_undo_method(self, "_set_setting_on_dict", "scale", temp)

	undo_redo.add_do_method(self, "_update_preview_transform")
	undo_redo.add_undo_method(self, "_update_preview_transform")

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------------


## Update the portrait offset X position
func _on_offset_x_value_changed(value: float) -> void:
	var temp = _transform_settings.offset.x
	_transform_settings.offset.x = value
	var offset_x_field = _portrait_offset_section.get_node("XField")

	_preview_container.position.x = value
	modified.emit(true)

	# --- UndoRedo --------------------------------------------------------
	undo_redo.create_action("Change Portrait Offset X")
	undo_redo.add_do_method(offset_x_field, "set_value_no_signal", value)
	undo_redo.add_undo_method(offset_x_field, "set_value_no_signal", temp)

	undo_redo.add_do_method(self, "_set_setting_on_dict", "offset",
			Vector2(value, _transform_settings.offset.y))
	undo_redo.add_undo_method(self, "_set_setting_on_dict", "offset",
			Vector2(temp, _transform_settings.offset.y))

	undo_redo.add_do_method(self, "_update_preview_transform")
	undo_redo.add_undo_method(self, "_update_preview_transform")

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------------


## Update the portrait offset Y position
func _on_offset_y_value_changed(value: float) -> void:
	var temp = _transform_settings.offset.y
	_transform_settings.offset.y = value
	var offset_y_field = _portrait_offset_section.get_node("YField")

	_preview_container.position.y = value
	modified.emit(true)

	# --- UndoRedo --------------------------------------------------------
	undo_redo.create_action("Change Portrait Offset Y")
	undo_redo.add_do_method(offset_y_field, "set_value_no_signal", value)
	undo_redo.add_undo_method(offset_y_field, "set_value_no_signal", temp)

	undo_redo.add_do_method(self, "_set_setting_on_dict", "offset",
			Vector2(_transform_settings.offset.x, value))
	undo_redo.add_undo_method(self, "_set_setting_on_dict", "offset",
			Vector2(_transform_settings.offset.x, temp))
	
	undo_redo.add_do_method(self, "_update_preview_transform")
	undo_redo.add_undo_method(self, "_update_preview_transform")

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------------


## Update the portrait rotation
func _on_rotation_value_changed(value: float) -> void:
	var temp = _transform_settings.rotation
	_transform_settings.rotation = value
	var rotation_field = _portrait_rotation_section.get_node("RotationField")

	_preview_container.rotation_degrees = value
	modified.emit(true)

	# --- UndoRedo --------------------------------------------------------
	undo_redo.create_action("Change Portrait Rotation")
	undo_redo.add_do_method(rotation_field, "set_value_no_signal", value)
	undo_redo.add_undo_method(rotation_field, "set_value_no_signal", temp)
	undo_redo.add_do_method(self, "_set_setting_on_dict", "rotation", value)
	undo_redo.add_undo_method(self, "_set_setting_on_dict", "rotation", temp)

	undo_redo.add_do_method(self, "_update_preview_transform")
	undo_redo.add_undo_method(self, "_update_preview_transform")

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------------


## Update the portrait mirroring
func _on_mirror_check_box_toggled(toggled_on: bool) -> void:
	var temp = _transform_settings.mirror
	_transform_settings.mirror = toggled_on
	var mirror_check_box = _portrait_rotation_section.get_node("MirrorCheckBox")

	_preview_container.scale.x *= -1
	modified.emit(true)
	
	# --- UndoRedo --------------------------------------------------------
	undo_redo.create_action("Toggle Mirror Portrait")
	undo_redo.add_do_method(mirror_check_box, "set_pressed_no_signal", toggled_on)
	undo_redo.add_undo_method(mirror_check_box, "set_pressed_no_signal", temp)
	undo_redo.add_do_method(self, "_set_setting_on_dict", "mirror", toggled_on)
	undo_redo.add_undo_method(self, "_set_setting_on_dict", "mirror", temp)

	undo_redo.add_do_method(self, "_update_preview_transform")
	undo_redo.add_undo_method(self, "_update_preview_transform")

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------------

#endregion

#region === Exported Properties =================================================

func _on_export_property_changed(name: String, value: Variant) -> void:
	# Override the property value in the preview scene
	_preview_container.get_child(0).set(name, value)

	# Update the portrait preview scene
	if _preview_container.get_child(0).has_method("set_portrait"):
			_preview_container.get_child(0).set_portrait()

#endregion

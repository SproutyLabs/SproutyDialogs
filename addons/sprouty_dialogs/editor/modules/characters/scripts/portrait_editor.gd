@tool
class_name EditorSproutyDialogsPortraitEditor
extends VBoxContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs Portrait Editor
# ----------------------------------------------------------------------------- 
## This module allows the user to edit a portrait for a character.
## It provides a preview of the portrait and allows the user to set
## various properties and settings.
# -----------------------------------------------------------------------------

## Emitted when the portrait is modified
signal modified(modified: bool)

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
## Portrait scale section
@onready var _portrait_transform_settings: PanelContainer = %TransformSettings

## Collapse/Expand icon resources
var _collapse_up_icon = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-up.svg")
var _collapse_down_icon = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-down.svg")

## Parent transform settings
var _main_transform: Dictionary = {
	"scale": Vector2.ONE,
	"scale_lock_ratio": true,
	"offset": Vector2.ZERO,
	"rotation": 0.0,
	"mirror": false
}

## Path of the current portrait scene
var _portrait_scene_path: String = ""
## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready():
	_to_portrait_scene_button.button_down.connect(_on_to_portrait_scene_button_pressed)
	_new_portrait_scene_button.button_down.connect(_on_new_portrait_scene_button_pressed)
	_new_portrait_scene_dialog.file_selected.connect(_new_portrait_scene)
	_portrait_scene_field.path_changed.connect(_on_portrait_scene_path_changed)
	
	_portrait_export_properties.property_changed.connect(_on_export_property_changed)
	_portrait_export_properties.modified.connect(modified.emit)

	_portrait_transform_settings.modified.connect(modified.emit)
	_portrait_transform_settings.transform_settings_changed.connect(update_preview_transform)

	%ReloadSceneButton.icon = get_theme_icon("Reload", "EditorIcons")
	%PreviewPivot.texture = get_theme_icon("EditorPivot", "EditorIcons")
	_new_portrait_scene_button.icon = get_theme_icon("Add", "EditorIcons")
	_to_portrait_scene_button.icon = get_theme_icon("PackedScene", "EditorIcons")

	_new_portrait_scene_button.visible = true
	_to_portrait_scene_button.visible = false
	
	await get_tree().process_frame # Wait a frame to ensure the UndoRedo is ready
	_portrait_export_properties.undo_redo = undo_redo
	_portrait_transform_settings.undo_redo = undo_redo


## Returns the portrait data from the editor
func get_portrait_data() -> SproutyDialogsPortraitData:
	var data = SproutyDialogsPortraitData.new()

	data.portrait_scene_uid = ResourceSaver.get_resource_id_for_path(
				_portrait_scene_field.get_value(), true) \
		if _check_valid_portrait_scene(_portrait_scene_field.get_value()) else -1
	
	data.portrait_scene_path = _portrait_scene_field.get_value() \
		if _check_valid_portrait_scene(_portrait_scene_field.get_value()) else ""
	
	data.export_overrides = _portrait_export_properties.get_export_overrides()
	data.transform_settings = _portrait_transform_settings.get_transform_settings()
	data.typing_sound = {} # Typing sound is not implemented yet
	return data


## Load the portrait data into the editor
## The name parameter is used to set the portrait name in the preview.
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

	# Load transform settings
	_portrait_transform_settings.set_transform_settings(data.transform_settings)
	update_preview_transform() # Update the preview image with the loaded settings


## Set the portrait name in the editor
func set_portrait_name(name: String) -> void:
	_portrait_name.text = name

#region === Portrait Preview ===================================================

## Update the preview scene with the transformation settings
func update_preview_transform(main_transform: Dictionary = {}) -> void:
	var settings = _portrait_transform_settings.get_transform_settings()

	if main_transform != {}:
		_main_transform = main_transform
	
	# Add the parent transform
	if not settings.ignore_main_transform:
		settings.scale += _main_transform.scale
		settings.offset += _main_transform.offset
		settings.rotation += _main_transform.rotation
		settings.mirror = not _main_transform.mirror \
				if settings.mirror else _main_transform.mirror

	_preview_container.scale = settings.scale
	_preview_container.position = settings.offset
	_preview_container.rotation_degrees = settings.rotation
	
	if settings.mirror:
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
	update_preview_transform(_main_transform)


## Reload the current scene in the preview
func _on_reload_scene_button_pressed() -> void:
	if _portrait_scene_field.get_value() != "":
		_switch_scene_preview(_portrait_scene_field.get_value())
	else:
		printerr("[Sprouty Dialogs] No scene file selected.")
		return
	update_preview_transform(_main_transform)

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
	SproutyDialogsFileUtils.create_new_scene_file(scene_path, "portrait_scene")

	# Set the field and preview to the new scene file
	_portrait_scene_field.set_value(scene_path)
	_on_portrait_scene_path_changed(scene_path)

	# Open the new scene in the editor
	SproutyDialogsFileUtils.open_scene_in_editor(scene_path, get_tree())
	modified.emit(true)


## Open the portrait scene in the editor
func _on_to_portrait_scene_button_pressed() -> void:
	if _portrait_scene_field.get_value() != "":
		SproutyDialogsFileUtils.open_scene_in_editor(
				_portrait_scene_field.get_value(), get_tree())
	else:
		printerr("[Sprouty Dialogs] No scene file selected.")

#endregion

#region === Transform Settings =================================================

## Show or hide the transform settings section
func _on_expand_transform_settings_toggled(toggled_on: bool) -> void:
	if _portrait_transform_settings:
		_portrait_transform_settings.visible = toggled_on
	%ExpandTransformSettingsButton.icon = _collapse_up_icon if toggled_on else _collapse_down_icon

#endregion

#region === Exported Properties =================================================

func _on_export_property_changed(name: String, value: Variant) -> void:
	# Override the property value in the preview scene
	_preview_container.get_child(0).set(name, value)

	# Update the portrait preview scene
	if _preview_container.get_child(0).has_method("set_portrait"):
			_preview_container.get_child(0).set_portrait()

#endregion

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
@onready var _portrait_scene_field: EditorSproutyDialogsSceneField = %PortraitSceneField
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
	# Set portrait scene field and connect signals
	_portrait_scene_field.set_scene_type(_portrait_scene_field.SceneType.PORTRAIT)
	_portrait_scene_field.scene_path_changed.connect(_on_portrait_scene_path_changed)

	# Connect siganls
	_portrait_export_properties.property_changed.connect(_on_export_property_changed)
	_portrait_export_properties.modified.connect(modified.emit)
	_portrait_transform_settings.modified.connect(modified.emit)
	_portrait_transform_settings.transform_settings_changed.connect(update_preview_transform)

	%ReloadSceneButton.icon = get_theme_icon("Reload", "EditorIcons")
	%PreviewPivot.texture = get_theme_icon("EditorPivot", "EditorIcons")
	
	await get_tree().process_frame # Wait a frame to ensure the UndoRedo is ready
	_portrait_export_properties.undo_redo = undo_redo
	_portrait_transform_settings.undo_redo = undo_redo


## Set the portrait name in the editor
func set_portrait_name(name: String) -> void:
	_portrait_name.text = name


#region === Portrait Data ======================================================

## Returns the portrait data from the editor
func get_portrait_data() -> SproutyDialogsPortraitData:
	var data = SproutyDialogsPortraitData.new()
	data.portrait_scene_uid = _portrait_scene_field.get_scene_uid()
	data.portrait_scene_path = _portrait_scene_field.get_scene_path()
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
		_portrait_scene_field.set_scene_path("")
	else:
		_portrait_scene_path = ResourceUID.get_id_path(data.portrait_scene_uid)
		_portrait_scene_field.set_scene_path(_portrait_scene_path)
	
	_portrait_export_properties.set_export_overrides(data.export_overrides)
	
	# Check if the scene file is valid and set the preview
	if not _portrait_export_properties.undo_redo:
		_portrait_export_properties.undo_redo = undo_redo
	_switch_scene_preview(_portrait_scene_field.get_scene_path())

	# Load transform settings
	_portrait_transform_settings.set_transform_settings(data.transform_settings)
	update_preview_transform() # Update the preview image with the loaded settings

#endregion

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
	_switch_scene_preview(_portrait_scene_field.get_scene_path())
	update_preview_transform(_main_transform)

#endregion

## Update the portrait scene when the path changes
func _on_portrait_scene_path_changed(path: String) -> void:
	var temp = _portrait_scene_path
	_portrait_scene_path = path
	_switch_scene_preview(_portrait_scene_path)
	modified.emit(true)
	
	# --- UndoRedo --------------------------------------------------------
	undo_redo.create_action("Change Portrait Scene")
	undo_redo.add_do_method(_portrait_scene_field, "set_scene_path", path)
	undo_redo.add_undo_method(_portrait_scene_field, "set_scene_path", temp)
	undo_redo.add_do_property(self , "_portrait_scene_path", path)
	undo_redo.add_undo_property(self , "_portrait_scene_path", temp)
	
	undo_redo.add_do_method(self , "_switch_scene_preview", _portrait_scene_path)
	undo_redo.add_undo_method(self , "_switch_scene_preview", temp)

	undo_redo.add_do_method(self , "emit_signal", "modified", true)
	undo_redo.add_undo_method(self , "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------------


## Show or hide the transform settings section
func _on_expand_transform_settings_toggled(toggled_on: bool) -> void:
	if _portrait_transform_settings:
		_portrait_transform_settings.visible = toggled_on
	%ExpandTransformSettingsButton.icon = _collapse_up_icon if toggled_on else _collapse_down_icon


func _on_export_property_changed(name: String, value: Variant) -> void:
	# Override the property value in the preview scene
	if value is Dictionary:
		value = SproutyDialogsVariableUtils.get_dictionary_from_data(value)
	elif value is Array:
		value = SproutyDialogsVariableUtils.get_array_from_data(value)
	
	_preview_container.get_child(0).set(name, value)

	# Update the portrait preview scene
	if _preview_container.get_child(0).has_method("set_portrait"):
			_preview_container.get_child(0).set_portrait()

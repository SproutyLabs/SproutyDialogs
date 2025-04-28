@tool
extends VBoxContainer

## -----------------------------------------------------------------------------
## Portrait Editor
## 
## This module allows the user to edit a portrait for a character.
## It provides a preview of the portrait and allows the user to set
## various properties and settings.
## -----------------------------------------------------------------------------

## Character editor reference
@onready var _character_editor: Container = find_parent("CharacterEditor")
## Character editor new scene dialog
@onready var _new_scene_dialog: FileDialog = _character_editor.new_scene_dialog if _character_editor else null

## Portrait name label
@onready var _portrait_name: Label = $Title/PortraitName
## Portrait preview pivot node
@onready var _preview_container: Node2D = %PreviewContainer
## Portrait preview image node
@onready var _image_preview: Sprite2D = %ImagePreview

## Portrait scene path field
@onready var _portrait_scene_field: GDialogsFileField = %PortraitSceneField
## Button to go to the portrait scene
@onready var _to_portrait_scene_button: Button = %ToPortraitSceneButton
## Button to create a new portrait scene
@onready var _new_portrait_scene_button: Button = %NewPortraitSceneButton

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

## Portrait image scene template
var _default_portrait_scene := preload("res://addons/graph_dialog_system/utils/dialog_nodes/default_portrait.tscn")
## Portrait custom script template
var _portrait_script_template := "res://addons/graph_dialog_system/utils/dialog_nodes/dialog_portrait_template.gd"

# Offset of the preview node position
var _preview_offset: Vector2 = Vector2(20, 20)


func _ready():
	_new_portrait_scene_button.visible = true
	_to_portrait_scene_button.visible = false
	%ReloadSceneButton.icon = get_theme_icon("Reload", "EditorIcons")
	%PreviewPivot.texture = get_theme_icon("EditorPivot", "EditorIcons")
	_new_portrait_scene_button.icon = get_theme_icon("Add", "EditorIcons")
	_to_portrait_scene_button.icon = get_theme_icon("PackedScene", "EditorIcons")
	_portrait_scale_section.get_node("LockRatioButton").icon = get_theme_icon("Instance", "EditorIcons")
	
	_portrait_export_properties.connect("property_changed", _on_export_property_changed)


## Get the portrait data from the editor
func get_portrait_data() -> Dictionary:
	var data = {
		"portrait_scene": _portrait_scene_field.get_value(),
		"export_overrides": _portrait_export_properties.get_export_overrides(),
		"transform_settings": {
			"scale": {
				"x": _portrait_scale_section.get_node("XField").value,
				"y": _portrait_scale_section.get_node("YField").value,
				"lock_ratio": _portrait_scale_section.get_node("LockRatioButton").button_pressed,
			},
			"offset": {
				"x": _portrait_offset_section.get_node("XField").value,
				"y": _portrait_offset_section.get_node("YField").value,
			},
			"rotation": _portrait_rotation_section.get_node("RotationField").value,
			"mirror": _portrait_rotation_section.get_node("MirrorCheckBox").button_pressed
		},
		"typing_sound": "",
	}
	return data


## Load the portrait settings into the editor
func load_portrait_data(name: String, data: Dictionary) -> void:
	# Load the portrait settings from the given data
	set_portrait_name(name)
	_portrait_scene_field.set_value(data.portrait_scene)
	_portrait_export_properties.set_export_overrides(data.export_overrides)

	# Check if the scene file is valid and set the preview
	if GDialogsFileUtils.check_valid_extension(
			data.portrait_scene, _portrait_scene_field.file_filters):
		_to_portrait_scene_button.visible = true
		_new_portrait_scene_button.visible = false
		_switch_scene_preview(data.portrait_scene)
	else:
		_to_portrait_scene_button.visible = false
		_new_portrait_scene_button.visible = true

	# Load image settings
	_portrait_scale_section.get_node("LockRatioButton").button_pressed = data.transform_settings.scale.lock_ratio
	_portrait_scale_section.get_node("XField").value = data.transform_settings.scale.x
	_portrait_scale_section.get_node("YField").value = data.transform_settings.scale.y

	_portrait_offset_section.get_node("XField").value = data.transform_settings.offset.x
	_portrait_offset_section.get_node("YField").value = data.transform_settings.offset.y

	_portrait_rotation_section.get_node("RotationField").value = data.transform_settings.rotation
	_portrait_rotation_section.get_node("MirrorCheckBox").button_pressed = data.transform_settings.mirror
	
	_update_preview() # Update the preview image with the loaded settings


## Set the portrait name in the editor
func set_portrait_name(name: String) -> void:
	_portrait_name.text = name

#region === Portrait Preview ===================================================

## Update the preview scene with transform settings
func _update_preview() -> void:
	_preview_container.scale = Vector2(
		_portrait_scale_section.get_node("XField").value,
		_portrait_scale_section.get_node("YField").value
		)
	_preview_container.position = Vector2(
		_portrait_offset_section.get_node("XField").value + _preview_offset.x,
		_portrait_offset_section.get_node("YField").value + _preview_offset.y
		)
	_preview_container.rotation_degrees = _portrait_rotation_section.get_node("RotationField").value
	
	if _portrait_rotation_section.get_node("MirrorCheckBox").button_pressed:
		_preview_container.scale.x = - _preview_container.scale.x


## Switch the portrait scene in the preview
func _switch_scene_preview(new_scene: String) -> void:
	if not new_scene:
		return # If the path is empty, do nothing
	
	# Switch the preview to the scene file path
	if _preview_container.get_child_count() > 0:
		_preview_container.remove_child(_preview_container.get_child(0))
	var scene = load(new_scene).instantiate()
	_preview_container.add_child(scene)
	_portrait_export_properties.load_exported_properties(scene)

func _on_reload_scene_button_pressed() -> void:
	# Reload the current scene in the preview
	if _portrait_scene_field.get_value() != "":
		_switch_scene_preview(_portrait_scene_field.get_value())
	else:
		printerr("[Graph Dialogs] No scene file selected.")
		return
	_update_preview()

#endregion

#region === Portrait Scene =====================================================

## Update the portrait scene when the path changes
func _on_portrait_scene_path_changed(path: String) -> void:
	# Check if the path is not empty and has a valid file extension
	if not GDialogsFileUtils.check_valid_extension(path, _portrait_scene_field.file_filters):
		_to_portrait_scene_button.visible = false
		return
	# Load the scene file if exist and set it as the preview
	if FileAccess.file_exists(path):
		_to_portrait_scene_button.visible = true
		_switch_scene_preview(path)
		_character_editor.on_modified()
	else:
		printerr("[Graph Dialogs] File " + path + " not found.")


## Select a path to create a new portrait scene file
func _on_new_portrait_scene_button_pressed() -> void:
	if not _new_scene_dialog.is_connected("file_selected", _new_portrait_scene):
		_new_scene_dialog.connect("file_selected", _new_portrait_scene)
	_new_scene_dialog.set_current_dir(GDialogsFileUtils.get_recent_file_path("portrait_files"))
	_new_scene_dialog.get_line_edit().text = "new_portrait.tscn"
	_new_scene_dialog.popup_centered()


## Create a new portrait scene file
func _new_portrait_scene(scene_path: String) -> void:
	var new_scene := _default_portrait_scene.instantiate()
	new_scene.name = scene_path.get_file().split(".")[0].to_pascal_case()

	# Creates and set a template script for the new scene
	var script_path := scene_path.get_basename() + ".gd"
	var script = GDScript.new()
	script.source_code = FileAccess.get_file_as_string(_portrait_script_template)
	ResourceSaver.save(script, script_path)
	new_scene.set_script(load(script_path))

	# Save the new scene file
	var packed_scene = PackedScene.new()
	packed_scene.pack(new_scene)
	ResourceSaver.save(packed_scene, scene_path)
	new_scene.queue_free()

	# Set the field and preview to the new scene file
	_portrait_scene_field.set_value(scene_path)
	_to_portrait_scene_button.visible = true
	_switch_scene_preview(scene_path)

	# Open the new scene in the editor
	_character_editor.open_scene_in_editor(scene_path)
	_character_editor.on_modified()

	# Set the recent file path
	GDialogsFileUtils.set_recent_file_path("portrait_files", scene_path)


## Open the portrait scene in the editor
func _on_to_portrait_scene_button_pressed() -> void:
	_character_editor.open_scene_in_editor(_portrait_scene_field.get_value())

#endregion

#region === Transform Settings =================================================

## Show or hide the image settings section
func _on_expand_transform_settings_toggled(toggled_on: bool) -> void:
	_transform_settings_section.visible = toggled_on


## Update the image scale lock ratio
func _on_scale_lock_ratio_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_portrait_scale_section.get_node("LockRatioButton").icon = get_theme_icon("Instance", "EditorIcons")
	else:
		_portrait_scale_section.get_node("LockRatioButton").icon = get_theme_icon("Unlinked", "EditorIcons")


## Update the image scale
func _on_scale_x_value_changed(value: float) -> void:
	_preview_container.scale.x = value
	if _portrait_scale_section.get_node("LockRatioButton").button_pressed:
		_portrait_scale_section.get_node("YField").value = value
		_preview_container.scale.y = value
	_character_editor.on_modified()

## Update the image scale
func _on_scale_y_value_changed(value: float) -> void:
	_preview_container.scale.y = value
	if _portrait_scale_section.get_node("LockRatioButton").button_pressed:
		_portrait_scale_section.get_node("XField").value = value
		_preview_container.scale.x = value
	_character_editor.on_modified()


## Update the image offset position
func _on_offset_x_value_changed(value: float) -> void:
	_preview_container.position.x = value + _preview_offset.x
	_character_editor.on_modified()


## Update the image offset position
func _on_offset_y_value_changed(value: float) -> void:
	_preview_container.position.y = value + _preview_offset.y
	_character_editor.on_modified()


## Update the image rotation
func _on_rotation_value_changed(value: float) -> void:
	_preview_container.rotation_degrees = value
	_character_editor.on_modified()


## Update the image mirroring
func _on_mirror_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_preview_container.scale.x = - abs(_preview_container.scale.x)
	else:
		_preview_container.scale.x = abs(_preview_container.scale.x)
	_character_editor.on_modified()

#endregion

#region === Exported Properties =================================================

func _on_export_property_changed(name: String, value: Variant) -> void:
	# Override the property value in the preview scene
	_preview_container.get_child(0).set(name, value)

	# Update the portrait preview scene
	if _preview_container.get_child(0).has_method("update_portrait"):
			_preview_container.get_child(0).update_portrait()
	_character_editor.on_modified()

#endregion

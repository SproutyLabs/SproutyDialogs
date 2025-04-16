@tool
extends VBoxContainer

## Character editor reference
@onready var _character_editor: Container = find_parent("CharacterEditor")

## Portrait name label
@onready var _portrait_name: Label = $Title/PortraitName
## Portrait preview pivot node
@onready var _preview_container: Node2D = %PreviewContainer
## Portrait preview image node
@onready var _image_preview: Sprite2D = %ImagePreview

## Portrait image and display section
@onready var _portrait_image_section: Container = %PortraitImageSection
## Portrait image file path field
@onready var _portrait_image_field: GDialogsFileField = %ImageFileField
## Portrait display scene file path field
@onready var _portrait_display_field: GDialogsFileField = %DisplayFileField
## Portrait scene file path field
@onready var _portrait_scene_field: GDialogsFileField = %SceneFileField
## Use scene as portrait check box
@onready var _scene_as_portrait_toggle: CheckButton = %SceneAsPortraitToggle
## Button to go to the portrait scene
@onready var _to_portrait_scene_button: Button = %ToPortraitSceneButton

## Image settings section
@onready var _image_settings_section: Container = %ImageSettings
## Portrait scale section
@onready var _image_scale_section: Container = %PortraitScale
## Portrait rotation and mirror section
@onready var _image_rotation_section: Container = %PortraitRotation
## Portrait offset section
@onready var _image_offset_section: Container = %PortraitOffset
## Portrait region section
@onready var _image_region_section: Container = %PortraitRegion
## Portrait region toggle button
@onready var _image_region_toggle: CheckButton = %RegionToggle

# Offset of the preview node position
var _preview_offset: Vector2 = Vector2(20, 20)


func _ready():
	%PreviewPivot.texture = get_theme_icon("EditorPivot", "EditorIcons")
	_to_portrait_scene_button.icon = get_theme_icon("PackedScene", "EditorIcons")
	_image_scale_section.get_node("LockRatioButton").icon = get_theme_icon("Instance", "EditorIcons")


## Get the portrait settings from the editor
func get_portrait_data() -> Dictionary:
	var data = {
		"portrait_image": _portrait_image_field.get_value(),
		"portrait_display": _portrait_display_field.get_value(),
		"portrait_scene": _portrait_scene_field.get_value(),
		"scene_as_portrait": _scene_as_portrait_toggle.button_pressed,
		"image_settings": {
			"scale": {
				"x": _image_scale_section.get_node("XField").value,
				"y": _image_scale_section.get_node("YField").value,
				"lock_ratio": _image_scale_section.get_node("LockRatioButton").button_pressed,
			},
			"offset": {
				"x": _image_offset_section.get_node("XField").value,
				"y": _image_offset_section.get_node("YField").value,
			},
			"rotation": _image_rotation_section.get_node("RotationField").value,
			"mirror": _image_rotation_section.get_node("MirrorCheckBox").button_pressed,
			"enable_region": _image_region_toggle.button_pressed,
			"region": {
				"x": _image_region_section.get_node("RegionPosition/XField").value,
				"y": _image_region_section.get_node("RegionPosition/YField").value,
				"width": _image_region_section.get_node("RegionSize/WField").value,
				"height": _image_region_section.get_node("RegionSize/HField").value,
			}
		},
		"typing_sound": "",
	}
	return data


## Load the portrait settings into the editor
func load_portrait_data(name: String, data: Dictionary) -> void:
	# Load the portrait settings from the given data
	set_portrait_name(name)
	_portrait_image_field.set_value(data.portrait_image)
	_portrait_display_field.set_value(data.portrait_display)
	_portrait_scene_field.set_value(data.portrait_scene)
	_scene_as_portrait_toggle.button_pressed = data.scene_as_portrait

	# Load image settings
	_image_scale_section.get_node("LockRatioButton").button_pressed = data.image_settings.scale.lock_ratio
	_image_scale_section.get_node("XField").value = data.image_settings.scale.x
	_image_scale_section.get_node("YField").value = data.image_settings.scale.y

	_image_offset_section.get_node("XField").value = data.image_settings.offset.x
	_image_offset_section.get_node("YField").value = data.image_settings.offset.y

	_image_rotation_section.get_node("RotationField").value = data.image_settings.rotation
	_image_rotation_section.get_node("MirrorCheckBox").button_pressed = data.image_settings.mirror

	_image_region_section.get_node("RegionPosition/XField").value = data.image_settings.region.x
	_image_region_section.get_node("RegionPosition/YField").value = data.image_settings.region.y
	_image_region_section.get_node("RegionSize/WField").value = data.image_settings.region.width
	_image_region_section.get_node("RegionSize/HField").value = data.image_settings.region.height
	_image_region_toggle.button_pressed = data.image_settings.enable_region

	_update_preview() # Update the preview image with the loaded settings


## Set the portrait name in the editor
func set_portrait_name(name: String) -> void:
	_portrait_name.text = name

#region === Preview handlers ===================================================

## Update the preview image with image settings
func _update_preview() -> void:
	_preview_container.scale = Vector2(
		_image_scale_section.get_node("XField").value,
		_image_scale_section.get_node("YField").value
		)
	_preview_container.position = Vector2(
		_image_offset_section.get_node("XField").value + _preview_offset.x,
		_image_offset_section.get_node("YField").value + _preview_offset.y
		)
	_preview_container.rotation_degrees = _image_rotation_section.get_node("RotationField").value
	
	if _image_rotation_section.get_node("MirrorCheckBox").button_pressed:
		_preview_container.scale.x = - _preview_container.scale.x

	_image_preview.region_enabled = _image_region_section.visible
	_image_preview.region_rect = Rect2(
		_image_region_section.get_node("RegionPosition/XField").value,
		_image_region_section.get_node("RegionPosition/YField").value,
		_image_region_section.get_node("RegionSize/WField").value,
		_image_region_section.get_node("RegionSize/HField").value
		)

## Update the portrait image when the path changes
func _on_portrait_image_path_changed(path: String) -> void:
	# Check if the path is not empty and has a valid file extension
	if not _character_editor.check_valid_file(path, _portrait_image_field.file_filters):
		return
	
	# Load the image file if exist and set it as the texture
	if FileAccess.file_exists(path):
		_image_preview.texture = load(path)
	else:
		printerr("[Graph Dialogs] Image file " + path + " not found.")


## Update the portrait scene when the path changes
func _on_portrait_scene_path_changed(path: String) -> void:
	# Check if the path is not empty and has a valid file extension
	if not _character_editor.check_valid_file(path, _portrait_scene_field.file_filters):
		_to_portrait_scene_button.visible = false
		return
	
	# Load the scene file if exist and set it as the preview
	if FileAccess.file_exists(path):
		_to_portrait_scene_button.visible = true
		_switch_scene_preview(path)
	else:
		printerr("[Graph Dialogs] Scene file " + path + " not found.")


## Switch the portrait scene in the preview
func _switch_scene_preview(new_scene: String) -> void:
	# Switch the preview to the scene file path
	if _preview_container.get_child_count() > 1:
		_preview_container.remove_child(_preview_container.get_child(1))
	var scene = load(new_scene).instantiate()
	_preview_container.add_child(scene)


## Change portrait to an image or scene
func _on_scene_as_portrait_toggled(toggled_on: bool) -> void:
	_portrait_image_section.visible = not toggled_on
	_image_preview.visible = not toggled_on
	_image_region_toggle.visible = not toggled_on
	
	if toggled_on: # If a scene is used as portrait, hide the image region section
		_image_region_section.visible = false
	else:
		_image_region_section.visible = _image_region_toggle.button_pressed

	_portrait_scene_field.get_parent().visible = toggled_on
	if _preview_container.get_child_count() > 1: # Show scene preview
		_preview_container.get_child(1).visible = toggled_on


## Open the portrait scene in the editor
func _on_to_portrait_scene_button_pressed() -> void:
	_character_editor.open_scene_in_editor(_portrait_scene_field.get_value())

#endregion

#region === Image settings =====================================================

## Show or hide the image settings section
func _on_expand_image_settings_toggled(toggled_on: bool) -> void:
	_image_settings_section.visible = toggled_on


## Show or hide the portrait region section
func _on_enable_region_toggled(toggled_on: bool) -> void:
	_image_region_section.visible = toggled_on
	_image_preview.region_enabled = toggled_on


## Update the image scale lock ratio
func _on_scale_lock_ratio_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_image_scale_section.get_node("LockRatioButton").icon = get_theme_icon("Instance", "EditorIcons")
	else:
		_image_scale_section.get_node("LockRatioButton").icon = get_theme_icon("Unlinked", "EditorIcons")


## Update the image scale
func _on_scale_x_value_changed(value: float) -> void:
	_preview_container.scale.x = value
	if _image_scale_section.get_node("LockRatioButton").button_pressed:
		_image_scale_section.get_node("YField").value = value
		_preview_container.scale.y = value

## Update the image scale
func _on_scale_y_value_changed(value: float) -> void:
	_preview_container.scale.y = value
	if _image_scale_section.get_node("LockRatioButton").button_pressed:
		_image_scale_section.get_node("XField").value = value
		_preview_container.scale.x = value


## Update the image offset position
func _on_offset_x_value_changed(value: float) -> void:
	_preview_container.position.x = value + _preview_offset.x


## Update the image offset position
func _on_offset_y_value_changed(value: float) -> void:
	_preview_container.position.y = value + _preview_offset.y


## Update the image rotation
func _on_rotation_value_changed(value: float) -> void:
	_preview_container.rotation_degrees = value


## Update the image mirroring
func _on_mirror_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_preview_container.scale.x = - abs(_preview_container.scale.x)
	else:
		_preview_container.scale.x = abs(_preview_container.scale.x)


## Update the image region x coordinate
func _on_region_x_value_changed(value: float) -> void:
	_image_preview.region_rect.position.x = value


## Update the image region y coordinate
func _on_region_y_value_changed(value: float) -> void:
	_image_preview.region_rect.position.y = value


## Update the image region width
func _on_region_w_value_changed(value: float) -> void:
	_image_preview.region_rect.size.x = value


## Update the image region height
func _on_region_h_value_changed(value: float) -> void:
	_image_preview.region_rect.size.y = value

#endregion

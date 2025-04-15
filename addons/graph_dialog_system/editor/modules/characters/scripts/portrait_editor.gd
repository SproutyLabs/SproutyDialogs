@tool
extends VBoxContainer

## Portrait name label
@onready var _portrait_name: Label = $Title/PortraitName
## Portrait image preview
@onready var _image_preview: Sprite2D = %ImagePreview

## Portrait image file path field
@onready var _image_file_field: GDialogsFileField = %ImageFileField
## Portrait display scene file path field
@onready var _display_file_field: GDialogsFileField = %DisplayFileField

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


func _ready():
	_image_preview.texture = get_theme_icon("Add", "EditorIcons")
	_image_scale_section.get_node("LockRatioButton").icon = get_theme_icon("Instance", "EditorIcons")


## Get the portrait settings from the editor
func get_portrait_data() -> Dictionary:
	var data = {
		"portrait_image": _image_file_field.get_value(),
		"portrait_display": _display_file_field.get_value(),
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
			"enable_region": _image_region_section.visible,
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
	_image_file_field.set_value(data.portrait_image)
	_display_file_field.set_value(data.portrait_display)

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
	_image_region_section.visible = data.image_settings.enable_region

	_update_preview_image() # Update the preview image with the loaded settings


## Set the portrait name in the editor
func set_portrait_name(name: String) -> void:
	_portrait_name.text = name

## Update the portrait image when the path changes
func _on_portrait_image_path_changed(path: String) -> void:
	if path == "": # If the path is empty, set the default icon
		_image_preview.texture = get_theme_icon("Add", "EditorIcons")
	
	if FileAccess.file_exists(path): # Check if the file exists
		_image_preview.texture = load(path) # Load the image
	else:
		printerr("[Graph Dialogs] Image file " + path + " not found.")

#region === Image settings =====================================================

## Update the preview image with image settings
func _update_preview_image() -> void:
	_image_preview.scale = Vector2(
		_image_scale_section.get_node("XField").value,
		_image_scale_section.get_node("YField").value
		)
	_image_preview.offset = Vector2(
		_image_offset_section.get_node("XField").value,
		_image_offset_section.get_node("YField").value
		)
	_image_preview.rotation_degrees = _image_rotation_section.get_node("RotationField").value
	_image_preview.flip_h = _image_rotation_section.get_node("MirrorCheckBox").button_pressed
	_image_preview.region_enabled = _image_region_section.visible
	_image_preview.region_rect = Rect2(
		_image_region_section.get_node("RegionPosition/XField").value,
		_image_region_section.get_node("RegionPosition/YField").value,
		_image_region_section.get_node("RegionSize/WField").value,
		_image_region_section.get_node("RegionSize/HField").value
		)


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
	_image_preview.scale.x = value
	if _image_scale_section.get_node("LockRatioButton").button_pressed:
		_image_scale_section.get_node("YField").value = value
		_image_preview.scale.y = value

## Update the image scale
func _on_scale_y_value_changed(value: float) -> void:
	_image_preview.scale.y = value
	if _image_scale_section.get_node("LockRatioButton").button_pressed:
		_image_scale_section.get_node("XField").value = value
		_image_preview.scale.x = value


## Update the image offset position
func _on_offset_x_value_changed(value: float) -> void:
	_image_preview.offset.x = value


## Update the image offset position
func _on_offset_y_value_changed(value: float) -> void:
	_image_preview.offset.y = value


## Update the image rotation
func _on_rotation_value_changed(value: float) -> void:
	_image_preview.rotation_degrees = value


## Update the image mirroring
func _on_mirror_check_box_toggled(toggled_on: bool) -> void:
	_image_preview.flip_h = toggled_on


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

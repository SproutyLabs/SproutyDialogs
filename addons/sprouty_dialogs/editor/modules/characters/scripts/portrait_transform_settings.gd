@tool
extends PanelContainer

# -----------------------------------------------------------------------------
# Portrait Transform Settings
# -----------------------------------------------------------------------------
## This module handle the transform setting section for portraits.
## It allows the user to modify the properties and settings.
# -----------------------------------------------------------------------------

## Emitted when the portrait is modified
signal modified(modified: bool)
## Emitted when the transform settings changed
signal transform_settings_changed

## Portrait scale section
@onready var _portrait_scale_section: Container = %PortraitScale
## Portrait rotation and mirror section
@onready var _portrait_rotation_section: Container = %PortraitRotation
## Portrait offset section
@onready var _portrait_offset_section: Container = %PortraitOffset

## Ignore main transform toggle
var _ignore_main_transform_toggle: CheckButton

## Current transform settings
var _transform_settings: Dictionary = {
	"ignore_main_transform": false,
	"scale": Vector2.ONE,
	"scale_lock_ratio": true,
	"offset": Vector2.ZERO,
	"rotation": 0.0,
	"mirror": false
}
## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready():
	_portrait_scale_section.get_node("LockRatioButton").icon = get_theme_icon("Instance", "EditorIcons")
	if get_node_or_null("%IgnoreMainTransformToggle"):
		_ignore_main_transform_toggle = %IgnoreMainTransformToggle
		_ignore_main_transform_toggle.toggled.connect(_on_ignore_main_transform_toggled)


## Returns the transform settings
func get_transform_settings() -> Dictionary:
	_transform_settings = {
		"ignore_main_transform": _ignore_main_transform_toggle.button_pressed \
				if _ignore_main_transform_toggle else false,
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
	if not _ignore_main_transform_toggle:
		_transform_settings.erase("ignore_main_transform")
	return _transform_settings


## Load the transform settings
func set_transform_settings(data: Dictionary) -> void:
	if _ignore_main_transform_toggle:
		_ignore_main_transform_toggle.set_pressed_no_signal(data.ignore_main_transform)

	_portrait_scale_section.get_node("LockRatioButton").set_pressed_no_signal(
			data.scale_lock_ratio)
	_portrait_scale_section.get_node("XField").set_value_no_signal(data.scale.x)
	_portrait_scale_section.get_node("YField").set_value_no_signal(data.scale.y)

	_portrait_offset_section.get_node("XField").set_value_no_signal(data.offset.x)
	_portrait_offset_section.get_node("YField").set_value_no_signal(data.offset.y)

	_portrait_rotation_section.get_node("RotationField").set_value_no_signal(data.rotation)
	_portrait_rotation_section.get_node("MirrorCheckBox").set_pressed_no_signal(data.mirror)
	
	_transform_settings = data


## Set a transform setting in the dictionary
func _set_setting_on_dict(key: String, value: Variant) -> void:
	_transform_settings[key] = value


#region === Scale Settings =====================================================

## Handle when the ignore main transform toggle change
func _on_ignore_main_transform_toggled(toggled_on: bool) -> void:
	var temp = _transform_settings.ignore_main_transform
	_transform_settings.ignore_main_transform = toggled_on

	transform_settings_changed.emit()
	modified.emit(true)

	# --- UndoRedo --------------------------------------------------------
	undo_redo.create_action("Toggle Ignore Main Transform")
	undo_redo.add_do_method(_ignore_main_transform_toggle, "set_pressed_no_signal", toggled_on)
	undo_redo.add_undo_method(_ignore_main_transform_toggle, "set_pressed_no_signal", temp)
	undo_redo.add_do_method(self, "_set_setting_on_dict", "ignore_main_transform", toggled_on)
	undo_redo.add_undo_method(self, "_set_setting_on_dict", "ignore_main_transform", temp)

	undo_redo.add_do_method(self, "emit_signal", "transform_settings_changed")
	undo_redo.add_undo_method(self, "emit_signal", "transform_settings_changed")
	
	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------------


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
		transform_settings_changed.emit()
	
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

		undo_redo.add_do_method(self, "emit_signal", "transform_settings_changed")
		undo_redo.add_undo_method(self, "emit_signal", "transform_settings_changed")
	
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
	
	transform_settings_changed.emit()
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

	undo_redo.add_do_method(self, "emit_signal", "transform_settings_changed")
	undo_redo.add_undo_method(self, "emit_signal", "transform_settings_changed")

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
	
	transform_settings_changed.emit()
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

	undo_redo.add_do_method(self, "emit_signal", "transform_settings_changed")
	undo_redo.add_undo_method(self, "emit_signal", "transform_settings_changed")

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------------

#endregion

#region === Offset Settings ====================================================

## Update the portrait offset X position
func _on_offset_x_value_changed(value: float) -> void:
	var temp = _transform_settings.offset.x
	_transform_settings.offset.x = value
	var offset_x_field = _portrait_offset_section.get_node("XField")

	transform_settings_changed.emit()
	modified.emit(true)

	# --- UndoRedo --------------------------------------------------------
	undo_redo.create_action("Change Portrait Offset X")
	undo_redo.add_do_method(offset_x_field, "set_value_no_signal", value)
	undo_redo.add_undo_method(offset_x_field, "set_value_no_signal", temp)

	undo_redo.add_do_method(self, "_set_setting_on_dict", "offset",
			Vector2(value, _transform_settings.offset.y))
	undo_redo.add_undo_method(self, "_set_setting_on_dict", "offset",
			Vector2(temp, _transform_settings.offset.y))

	undo_redo.add_do_method(self, "emit_signal", "transform_settings_changed")
	undo_redo.add_undo_method(self, "emit_signal", "transform_settings_changed")

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------------


## Update the portrait offset Y position
func _on_offset_y_value_changed(value: float) -> void:
	var temp = _transform_settings.offset.y
	_transform_settings.offset.y = value
	var offset_y_field = _portrait_offset_section.get_node("YField")

	transform_settings_changed.emit()
	modified.emit(true)

	# --- UndoRedo --------------------------------------------------------
	undo_redo.create_action("Change Portrait Offset Y")
	undo_redo.add_do_method(offset_y_field, "set_value_no_signal", value)
	undo_redo.add_undo_method(offset_y_field, "set_value_no_signal", temp)

	undo_redo.add_do_method(self, "_set_setting_on_dict", "offset",
			Vector2(_transform_settings.offset.x, value))
	undo_redo.add_undo_method(self, "_set_setting_on_dict", "offset",
			Vector2(_transform_settings.offset.x, temp))
	
	undo_redo.add_do_method(self, "emit_signal", "transform_settings_changed")
	undo_redo.add_undo_method(self, "emit_signal", "transform_settings_changed")

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------------

#endregion

#region === Rotation Settings ==================================================

## Update the portrait rotation
func _on_rotation_value_changed(value: float) -> void:
	var temp = _transform_settings.rotation
	_transform_settings.rotation = value
	var rotation_field = _portrait_rotation_section.get_node("RotationField")

	transform_settings_changed.emit()
	modified.emit(true)

	# --- UndoRedo --------------------------------------------------------
	undo_redo.create_action("Change Portrait Rotation")
	undo_redo.add_do_method(rotation_field, "set_value_no_signal", value)
	undo_redo.add_undo_method(rotation_field, "set_value_no_signal", temp)
	undo_redo.add_do_method(self, "_set_setting_on_dict", "rotation", value)
	undo_redo.add_undo_method(self, "_set_setting_on_dict", "rotation", temp)

	undo_redo.add_do_method(self, "emit_signal", "transform_settings_changed")
	undo_redo.add_undo_method(self, "emit_signal", "transform_settings_changed")

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------------


## Update the portrait mirroring
func _on_mirror_check_box_toggled(toggled_on: bool) -> void:
	var temp = _transform_settings.mirror
	_transform_settings.mirror = toggled_on
	var mirror_check_box = _portrait_rotation_section.get_node("MirrorCheckBox")

	transform_settings_changed.emit()
	modified.emit(true)
	
	# --- UndoRedo --------------------------------------------------------
	undo_redo.create_action("Toggle Mirror Portrait")
	undo_redo.add_do_method(mirror_check_box, "set_pressed_no_signal", toggled_on)
	undo_redo.add_undo_method(mirror_check_box, "set_pressed_no_signal", temp)
	undo_redo.add_do_method(self, "_set_setting_on_dict", "mirror", toggled_on)
	undo_redo.add_undo_method(self, "_set_setting_on_dict", "mirror", temp)

	undo_redo.add_do_method(self, "emit_signal", "transform_settings_changed")
	undo_redo.add_undo_method(self, "emit_signal", "transform_settings_changed")

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------------

#endregion
@tool
extends VBoxContainer

## -----------------------------------------------------------------------------
## Portrait Editor
## 
## This module allows the user to edit a portrait for a character.
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
@onready var _exported_properties_grid: Container = %ExportedProperties
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

## Dictionary to store the exported properties
var _export_overrides := {}

func _ready():
	_new_portrait_scene_button.visible = true
	_to_portrait_scene_button.visible = false
	_exported_properties_grid.get_parent().visible = false
	%ReloadSceneButton.icon = get_theme_icon("Reload", "EditorIcons")
	%PreviewPivot.texture = get_theme_icon("EditorPivot", "EditorIcons")
	_new_portrait_scene_button.icon = get_theme_icon("Add", "EditorIcons")
	_to_portrait_scene_button.icon = get_theme_icon("PackedScene", "EditorIcons")
	_portrait_scale_section.get_node("LockRatioButton").icon = get_theme_icon("Instance", "EditorIcons")


## Get the portrait data from the editor
func get_portrait_data() -> Dictionary:
	var data = {
		"portrait_scene": _portrait_scene_field.get_value(),
		"export_overrides": _export_overrides,
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
	_export_overrides = data.export_overrides

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
	load_exported_properties(scene)

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

# Load the exported properties from a portrait scene
func load_exported_properties(scene: Node) -> void:
	if not scene and scene.script:
		_exported_properties_grid.get_parent().visible = false
		return # If the scene has no script, do nothing
	
	var property_list: Array = scene.script.get_script_property_list()
	if property_list.size() < 1:
		_exported_properties_grid.get_parent().visible = false
		return # If the script has no properties, do nothing
	
	# Clear the previous properties
	for child in _exported_properties_grid.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()

	# Remove the first property (the script itself)
	property_list.remove_at(0)
	var in_private_group := false

	for prop in property_list:
		print(prop)
		if prop["usage"] and PROPERTY_USAGE_EDITOR and not in_private_group:
			var label := Label.new()
			label.text = prop["name"].capitalize()
			_exported_properties_grid.add_child(label)

			# Persist the current value of the property
			var value = null
			if prop["name"] in _export_overrides:
				value = _export_overrides[prop["name"]]
			else:
				# If is not in the overrides, get the value from the scene
				value = scene.get(prop["name"])
				_export_overrides[prop["name"]] = value

			# Add the exported property field to the editor
			var property_field: Control = new_property_field(prop, value)
			property_field.size_flags_horizontal = SIZE_EXPAND_FILL
			_exported_properties_grid.add_child(property_field)

		if prop["usage"] and PROPERTY_USAGE_GROUP:
			# If the group is private, skip the next properties
			if prop["name"] == "Private":
				in_private_group = true
				continue
			else: # Until the next group
				in_private_group = false
	
	_exported_properties_grid.get_parent().visible = true


# Create a new exported property field
func new_property_field(property_data: Dictionary, value: Variant) -> Control:
	var field = null
	match property_data["type"]:
		TYPE_BOOL:
			field = CheckBox.new()
			if value != null:
				field.button_pressed = value
			field.toggled.connect(_on_property_changed.bind(
					property_data["name"], property_data["type"]))
		
		TYPE_INT:
			# If the property is an enum, create an OptionButton
			if property_data["hint"] == PROPERTY_HINT_ENUM:
				field = OptionButton.new()
				for option in property_data["hint_string"].split(","):
					field.add_item(option.split(":")[0])
				if value != null:
					field.select(value)
				field.item_selected.connect(_on_property_changed.bind(
						property_data["name"], property_data["type"]))
			else:
				field = SpinBox.new()
				var range_settings = property_data["hint_string"].split(",")
				# If the property is a int between a range, set range values
				if range_settings.size() > 0:
					field.min_value = int(range_settings[0])
					field.max_value = int(range_settings[1])
					if range_settings.size() > 2:
						field.step = int(range_settings[2])
				else: # If not, set unlimited range
					field.step = 1
					field.allow_greater = true
					field.allow_lesser = true
				if value != null:
					field.value = value
				field.value_changed.connect(_on_property_changed.bind(
						property_data["name"], property_data["type"]))
		
		TYPE_FLOAT:
			field = SpinBox.new()
			var range_settings = property_data["hint_string"].split(",")
			# If the property is a float between a range, set range values
			if range_settings.size() > 0:
				field.min_value = float(range_settings[0])
				field.max_value = float(range_settings[1])
				if range_settings.size() > 2:
					field.step = float(range_settings[2])
			else: # If not, set unlimited range
				field.step = 0.01
				field.allow_greater = true
				field.allow_lesser = true
			if value != null:
				field.value = value
			field.value_changed.connect(_on_property_changed.bind(
					property_data["name"], property_data["type"]))
		
		TYPE_STRING:
			# If the property is a file path, create a file field
			if property_data["hint"] == PROPERTY_HINT_FILE:
				field = load("addons/graph_dialog_system/editor/components/file_field.tscn").instantiate()
				field.file_filters = PackedStringArray(property_data["hint_string"].split(","))
				if value != null:
					field.ready.connect(func(): field.set_value(value))
				field.file_path_changed.connect(
						_on_property_changed.bind(property_data["name"], property_data["type"]))
			# If the property is a directory path, create a folder field
			elif property_data["hint"] == PROPERTY_HINT_DIR:
				field = load("addons/graph_dialog_system/editor/components/folder_field.tscn").instantiate()
				field.file_filters = PackedStringArray(property_data["hint_string"].split(","))
				if value != null:
					field.ready.connect(func(): field.set_value(value))
				field.file_path_changed.connect(
						_on_property_changed.bind(property_data["name"], property_data["type"]))
			# If the property is an enum, create an OptionButton
			elif property_data["hint"] == PROPERTY_HINT_ENUM:
				field = OptionButton.new()
				var options := []
				for enum_option in property_data["hint_string"].split(","):
					options.append(enum_option.split(':')[0].strip_edges())
					field.add_item(options[-1])
				if value != null:
					field.select(options.find(value))
				field.item_selected.connect(
						_on_property_changed.bind(property_data["name"], property_data["type"]))
			else: # If the property is only a string, create a LineEdit
				field = LineEdit.new()
				if value != null:
					field.text = value
				field.text_submitted.connect(
						_on_property_changed.bind(property_data["name"], property_data["type"]))
		
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			var vector_n := int(type_string(property_data["type"])[-1])
			var components_names = ["x", "y", "z", "w"]
			field = HBoxContainer.new()
			# Create the fields for each component of the vector
			for i in range(0, vector_n):
				var label = Label.new()
				label.text = components_names[i]
				field.add_child(label)
				var x_field = SpinBox.new()
				x_field.step = 0.01
				x_field.allow_greater = true
				x_field.allow_lesser = true
				if value != null:
					x_field.value = value[i]
				field.add_child(x_field)
				x_field.value_changed.connect(_on_property_changed.bind(
						property_data["name"] + ":" + components_names[i], property_data["type"]))
		
		TYPE_COLOR:
			field = ColorPickerButton.new()
			if value != null:
				field.color = value
			field.color_changed.connect(
					_on_property_changed.bind(property_data["name"], property_data["type"]))
		
		TYPE_DICTIONARY:
			pass
		
		TYPE_ARRAY:
			field = load("addons/graph_dialog_system/editor/components/array_field.tscn").instantiate()
			if value != null:
				field.set_array(value)
			field.array_changed.connect(
					_on_property_changed.bind(property_data["name"], property_data["type"]))

		TYPE_OBJECT:
			field = RichTextLabel.new()
			field.bbcode_enabled = true
			field.fit_content = true
			field.text = "[color=red]Objects/Resources are not supported.[/color]"
			field.tooltip_text = "Use @export_file(\"*.extension\") to load the resource instead."
		_:
			field = LineEdit.new()
			if value != null:
				field.text = value
			field.text_submitted.connect(
					_on_property_changed.bind(property_data["name"], property_data["type"]))
	
	return field


## Update the exported properties and the preview scene when the value changes
func _on_property_changed(value: Variant, name: String, type: int) -> void:
	# If is changing a vector component, update the vector with the value
	if type == TYPE_VECTOR2 or type == TYPE_VECTOR3 or type == TYPE_VECTOR4:
		var vector_name = name.get_slice(":", 0)
		var vector_component = name.get_slice(":", 1)
		var old_vector = _preview_container.get_child(0).get(vector_name)
		_export_overrides[vector_name][vector_component] = value
		old_vector[vector_component] = value
		_preview_container.get_child(0).set(vector_name, old_vector)
	else:
		_export_overrides[name] = value
		_preview_container.get_child(0).set(name, value)
	
	# Update the preview scene with the new value
	if _preview_container.get_child(0).has_method("update_portrait"):
			_preview_container.get_child(0).update_portrait()
	_character_editor.on_modified()

	print("[Graph Dialogs] Property " + name + " changed to " + str(value))


#endregion

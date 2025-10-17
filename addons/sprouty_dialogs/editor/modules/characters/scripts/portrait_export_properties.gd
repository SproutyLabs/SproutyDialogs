@tool
extends VBoxContainer

# -----------------------------------------------------------------------------
## Portrait Export Properties
##
## This module shows the exported properties of a portrait scene in the editor.
## It allows the user to modify the properties and see the changes in real time.
# -----------------------------------------------------------------------------

## Emmited when a property is modified
signal modified(modified: bool)
## Emmited when a property value is changed
signal property_changed(name: String, value: Variant)

## Exported properties section
@onready var _properties_grid: Container = $ExportedPropertiesGrid
## Dictionary to store the exported properties
@onready var _export_overrides := {}

## File field scene
var _file_field_path := "res://addons/sprouty_dialogs/editor/components/file_field.tscn"
## Dictionary field scene
var _dict_field_path := "res://addons/sprouty_dialogs/editor/components/dictionary_field.tscn"
## Array field scene
var _array_field_path := "res://addons/sprouty_dialogs/editor/components/array_field.tscn"

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready():
	visible = false


## Return the current value of the exported properties
func get_export_overrides() -> Dictionary:
	return _export_overrides


## Set the exported properties
func set_export_overrides(overrides: Dictionary) -> void:
	_export_overrides = overrides


# Load the exported properties from a portrait scene
func load_exported_properties(scene: Node) -> void:
	if not scene and scene.script:
		visible = false
		return # If the scene has no script, do nothing
	
	var property_list: Array = scene.script.get_script_property_list()
	if property_list.size() < 1:
		visible = false
		return # If the script has no properties, do nothing
	
	_override_exported_properties(scene)
	_clear_exported_properties()
	var in_private_group := false

	for prop in property_list:
		if prop["usage"] == PROPERTY_USAGE_CATEGORY:
			continue # Skip the categories, they are not properties
		
		elif prop["usage"] == PROPERTY_USAGE_GROUP:
			# If the group is private, skip the next properties
			if prop["name"].to_lower() == "private":
				in_private_group = true
				continue
			else: # Until the next group
				in_private_group = false
		
		elif prop["usage"] and PROPERTY_USAGE_EDITOR and not in_private_group:
			var label := Label.new()
			label.text = prop["name"].capitalize()
			_properties_grid.add_child(label)

			var value = null
			# If the property is in the overrides, get the value from there
			if prop["name"] in _export_overrides:
				value = _export_overrides[prop["name"]]["value"]
				prop["type"] = _export_overrides[prop["name"]]["type"]
			else:
				# If is not in the overrides, get the value from the scene
				value = scene.get(prop["name"])
				if prop["type"] == TYPE_ARRAY:
					prop["type"] = _get_array_types(value)
				elif prop["type"] == TYPE_DICTIONARY:
					prop["type"] = _get_dictionary_types(value)
				
				_export_overrides[prop["name"]] = {
					"value": value,
					"type": prop["type"]
				}

			# Add the exported property field to the editor
			var property_field: Control = _new_property_field(prop, value)
			property_field.size_flags_horizontal = SIZE_EXPAND_FILL
			_properties_grid.add_child(property_field)

	visible = true


## Overrides the exported properties on a scene and update export overrides
func _override_exported_properties(scene: Node) -> void:
	var property_list: Array = scene.script.get_script_property_list()
	for prop in _export_overrides.keys():
		if property_list.any(func(p): return p["name"] == prop):
			scene.set(prop, _export_overrides[prop]["value"])
		else:
			_export_overrides.erase(prop)


## Get the types of the dictionary elements
func _get_dictionary_types(dictionary: Dictionary) -> Dictionary:
	var types = {}
	for key in dictionary.keys():
		if typeof(dictionary[key]) == TYPE_DICTIONARY:
			types[key] = _get_dictionary_types(dictionary[key])
		elif typeof(dictionary[key]) == TYPE_ARRAY:
			types[key] = _get_dictionary_types(dictionary[key])
		else:
			types[key] = typeof(dictionary[key])
	return types


## Get the types of the array elements
func _get_array_types(array: Array) -> Array:
	var types = []
	for i in range(0, array.size()):
		if typeof(array[i]) == TYPE_DICTIONARY:
			types.append(_get_dictionary_types(array[i]))
		elif typeof(array[i]) == TYPE_ARRAY:
			types.append(_get_array_types(array[i]))
		else:
			types.append(typeof(array[i]))
	return types


## Clear the exported properties from the editor
func _clear_exported_properties() -> void:
	for child in _properties_grid.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()


## Create a new exported property field
func _new_property_field(property_data: Dictionary, value: Variant) -> Control:
	var type: int = 0
	if typeof(property_data["type"]) == TYPE_DICTIONARY:
		type = TYPE_DICTIONARY
	elif typeof(property_data["type"]) == TYPE_ARRAY:
		type = TYPE_ARRAY
	else: type = property_data["type"]
	var field = null
	match type:
		TYPE_BOOL:
			field = CheckBox.new()
			if value != null:
				field.button_pressed = value
			field.toggled.connect(
				_on_property_changed.bind(property_data["name"], type, field))
		
		TYPE_INT:
			# Enum int
			if property_data["hint"] == PROPERTY_HINT_ENUM:
				field = OptionButton.new()
				for option in property_data["hint_string"].split(","):
					field.add_item(option.split(":")[0])
				if value != null:
					field.select(value)
				field.item_selected.connect(
					_on_property_changed.bind(property_data["name"], type, field))
			else:
				field = SpinBox.new()
				var range_settings = property_data["hint_string"].split(",")
				# If the property is a int between a range, set range values
				if range_settings.size() > 1:
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
				field.value_changed.connect(
					_on_property_changed.bind(property_data["name"], type, field))
		
		TYPE_FLOAT:
			field = SpinBox.new()
			var range_settings = property_data["hint_string"].split(",")
			# If the property is a float between a range, set range values
			if range_settings.size() > 1:
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
			field.value_changed.connect(
				_on_property_changed.bind(property_data["name"], type, field))
		
		TYPE_STRING:
			# File path string
			if property_data["hint"] == PROPERTY_HINT_FILE:
				field = load(_file_field_path).instantiate()
				field.file_filters = PackedStringArray(
					property_data["hint_string"].split(",")
					)
				if value != null:
					field.ready.connect(func(): field.set_value(value))
				field.path_changed.connect(
						_on_property_changed.bind(property_data["name"], type))
			# Directory path string
			elif property_data["hint"] == PROPERTY_HINT_DIR:
				field = load(_file_field_path).instantiate()
				field.open_directory(true)
				field.file_filters = PackedStringArray(
					property_data["hint_string"].split(",")
					)
				if value != null:
					field.ready.connect(func(): field.set_value(value))
				field.path_changed.connect(
						_on_property_changed.bind(property_data["name"], type, field))
			# Enum string
			elif property_data["hint"] == PROPERTY_HINT_ENUM:
				field = OptionButton.new()
				var options := []
				for enum_option in property_data["hint_string"].split(","):
					options.append(enum_option.split(':')[0].strip_edges())
					field.add_item(options[-1])
				if value != null:
					field.select(options.find(value))
				field.item_selected.connect(
						_on_property_changed.bind(property_data["name"], type, field))
			else:
				field = LineEdit.new()
				if value != null:
					field.text = value
				field.text_changed.connect(
						_on_property_changed.bind(property_data["name"], type, field))
		
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			var vector_n := int(type_string(property_data["type"])[-1])
			var components_names = ["x", "y", "z", "w"]
			field = HFlowContainer.new()
			# Create the fields for each component of the vector
			for i in range(0, vector_n):
				var container = HBoxContainer.new()
				field.add_child(container)
				var label = Label.new()
				label.text = components_names[i]
				container.add_child(label)
				var x_field = SpinBox.new()
				x_field.step = 0.01
				x_field.allow_greater = true
				x_field.allow_lesser = true
				if value != null:
					x_field.value = value[i]
				container.add_child(x_field)
				x_field.value_changed.connect(_on_property_changed.bind(
						property_data["name"] + "." + components_names[i], type, x_field))
		
		TYPE_COLOR:
			field = ColorPickerButton.new()
			if value != null:
				field.color = value
			field.color_changed.connect(
					_on_property_changed.bind(property_data["name"], type, field))
		
		TYPE_DICTIONARY:
			field = load(_dict_field_path).instantiate()
			if value != null:
				field.ready.connect(func():
					field.set_dictionary(value, property_data["type"]))
			field.dictionary_changed.connect(
					_on_property_changed.bind(property_data["name"], type, field))
		
		TYPE_ARRAY:
			field = load(_array_field_path).instantiate()
			if value != null:
				field.ready.connect(func():
					field.set_array(value, property_data["type"]))
			field.array_changed.connect(
					_on_property_changed.bind(property_data["name"], type, field))

		TYPE_OBJECT:
			field = RichTextLabel.new()
			field.bbcode_enabled = true
			field.fit_content = true
			field.text = "[color=tomato]Objects/Resources are not supported.[/color]"
			field.tooltip_text = "Use @export_file(\"*.extension\") to load the resource file instead."
		
		_:
			field = LineEdit.new()
			if value != null:
				field.text = value
			field.text_changed.connect(
					_on_property_changed.bind(property_data["name"], type, field))
	return field


## Set a property on the export overrides dictionary
func _set_property_on_dict(name: String, value: Variant, type: Variant) -> void:
	_export_overrides[name]["value"] = value
	_export_overrides[name]["type"] = type


## Update the exported properties when the value changes
func _on_property_changed(value: Variant, name: String, type: Variant, field: Variant = null) -> void:
	var temp = _export_overrides[name.get_slice(".", 0)].duplicate()
	var vector_component = name.get_slice(".", 1)
	
	match type:
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			# Update the changed component of the vector
			vector_component = ["x", "y", "z", "w"].find(vector_component)
			var vector_value = temp["value"]
			vector_value[vector_component] = value
			value = vector_value
		TYPE_ARRAY, TYPE_DICTIONARY: # Save each element type
			type = field.get_items_types()
		TYPE_COLOR: # Save color value as a hexadecimal string
			value = value.to_html()
	
	name = name.get_slice(".", 0) # Get the base property name
	print("_on_property_changed: ", name, " = ", value)
	_set_property_on_dict(name, value, type)
	property_changed.emit(name, value)
	modified.emit(true)

	# --- UndoRedo -------------------------------------------------------------
	undo_redo.create_action("Edit Portrait Property: " + name.capitalize())

	match type: # Handle specific field types for undo/redo
		TYPE_BOOL:
			if field is CheckBox: # Checkbox bool
				undo_redo.add_do_method(field, "set_pressed_no_signal", value)
				undo_redo.add_undo_method(field, "set_pressed_no_signal", temp["value"])
		TYPE_INT:
			if field is OptionButton: # Enum int
				undo_redo.add_do_method(field, "select", field.get_item_index(value))
				undo_redo.add_undo_method(field, "select", field.get_item_index(temp["value"]))
			elif field is SpinBox: # SpinBox int
				undo_redo.add_do_method(field, "set_value_no_signal", value)
				undo_redo.add_undo_method(field, "set_value_no_signal", temp["value"])
		TYPE_FLOAT:
			if field is SpinBox: # SpinBox float
				undo_redo.add_do_method(field, "set_value_no_signal", value)
				undo_redo.add_undo_method(field, "set_value_no_signal", temp["value"])
		TYPE_STRING:
			if field is EditorSproutyDialogsFileField: # File/Dir path string
				undo_redo.add_do_method(field, "set_value", value)
				undo_redo.add_undo_method(field, "set_value", temp["value"])
			elif field is OptionButton: # Enum string
				undo_redo.add_do_method(field, "select", field.get_item_index(value))
				undo_redo.add_undo_method(field, "select", field.get_item_index(temp["value"]))
			elif field is LineEdit: # LineEdit string
				undo_redo.add_do_property(field, "text", value)
				undo_redo.add_undo_property(field, "text", temp["value"])
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			if field is SpinBox: # Vector component SpinBox
				undo_redo.add_do_method(field, "set_value_no_signal", value[vector_component])
				undo_redo.add_undo_method(field, "set_value_no_signal", temp["value"][vector_component])
		TYPE_COLOR:
			if field is ColorPickerButton: # ColorPickerButton
				undo_redo.add_do_property(field, "color", value)
				undo_redo.add_undo_property(field, "color", temp["value"])
		TYPE_ARRAY:
			if field is EditorSproutyDialogsArrayField: # Array field
				undo_redo.add_do_method(field, "set_array", value, type)
				undo_redo.add_undo_method(field, "set_array", temp["value"], temp["type"])
		TYPE_DICTIONARY:
			if field is EditorSproutyDialogsDictionaryField: # Dictionary field
				undo_redo.add_do_method(field, "set_dictionary", value, type)
				undo_redo.add_undo_method(field, "set_dictionary", temp["value"], type)
		_:
			if field is LineEdit: # LineEdit default
				undo_redo.add_do_property(field, "text", value)
				undo_redo.add_undo_property(field, "text", temp["value"])

	undo_redo.add_do_method(self, "_set_property_on_dict", name, value, type)
	undo_redo.add_undo_method(self, "_set_property_on_dict", name, temp["value"], temp["type"])

	undo_redo.add_do_method(self, "emit_signal", "property_changed", name, value)
	undo_redo.add_undo_method(self, "emit_signal", "property_changed", name, temp["value"])

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# --------------------------------------------------------------------------
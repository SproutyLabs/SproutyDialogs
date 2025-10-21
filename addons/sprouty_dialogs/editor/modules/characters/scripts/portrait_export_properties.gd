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

## Modified properties tracker
var _properties_modified: Dictionary = {}
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
			_properties_modified[prop["name"]] = false

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
	var field_data = EditorSproutyDialogsVariableManager.new_field_by_type(
			type, value, property_data,
			_on_property_changed.bind(property_data["name"]),
			_on_property_modified.bind(property_data["name"])
		)
	return field_data.field


## Set a property on the export overrides dictionary
func _set_property_on_dict(name: String, value: Variant, type: Variant) -> void:
	_export_overrides[name]["value"] = value
	_export_overrides[name]["type"] = type


## Update the exported properties when the value changes
func _on_property_changed(value: Variant, type: Variant, field: Control, name: String) -> void:
	var temp = _export_overrides[name].duplicate()
	
	match type:
		TYPE_ARRAY, TYPE_DICTIONARY: # Save each element type
			type = field.get_items_types()
		TYPE_COLOR: # Save color value as a hexadecimal string
			value = value.to_html()
	
	print("_on_property_changed: ", name, " = ", value)
	_set_property_on_dict(name, value, type)
	property_changed.emit(name, value)
	_properties_modified[name] = true

	# --- UndoRedo -------------------------------------------------------------
	undo_redo.create_action("Edit Portrait Property: " + name.capitalize(), 1)

	undo_redo.add_do_method(EditorSproutyDialogsVariableManager,
			"set_field_value", field, type, value)
	undo_redo.add_undo_method(EditorSproutyDialogsVariableManager,
			"set_field_value", field, temp["type"], temp["value"])

	undo_redo.add_do_method(self, "_set_property_on_dict", name, value, type)
	undo_redo.add_undo_method(self, "_set_property_on_dict", name, temp["value"], temp["type"])

	undo_redo.add_do_method(self, "emit_signal", "property_changed", name, value)
	undo_redo.add_undo_method(self, "emit_signal", "property_changed", name, temp["value"])

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# --------------------------------------------------------------------------


## Handle when a property is modified
func _on_property_modified(name: String) -> void:
	if _properties_modified[name]:
		_properties_modified[name] = false
		modified.emit(true)
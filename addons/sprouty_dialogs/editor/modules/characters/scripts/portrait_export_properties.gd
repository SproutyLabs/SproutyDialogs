@tool
extends VBoxContainer

# -----------------------------------------------------------------------------
# Portrait Export Properties
# -----------------------------------------------------------------------------
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
## Flag to know if the properties have been loaded
var _properties_loaded: bool = false

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

				# Load collections items from the scene
				if prop["type"] == TYPE_ARRAY:
					value = _get_array_data(value)
				if prop["type"] == TYPE_DICTIONARY:
					value = _get_dictionary_data(value)
				
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
	_properties_loaded = true


#region === Handle Collections =================================================

## Recursively get array data from an array
func _get_array_data(array: Array) -> Array:
	var items = []
	for item in array:
		var type = typeof(item)
		if type == TYPE_DICTIONARY:
			item = _get_dictionary_data(item)
		if type == TYPE_ARRAY:
			item = _get_array_data(item)
		items.append({
			"type": typeof(item),
			"value": item,
			"metadata": {}
		})
	return items


## Recursively get dictionary data from a dictionary
func _get_dictionary_data(dict: Dictionary) -> Dictionary:
	var items = {}
	for key in dict.keys():
		var item = dict[key]
		var type = typeof(item)
		if type == TYPE_DICTIONARY:
			item = _get_dictionary_data(item)
		elif type == TYPE_ARRAY:
			item = _get_array_data(item)
		items[key] = {
			"type": typeof(item),
			"value": item,
			"metadata": {}
		}
	return items


## Recursively get array from array data
func _get_array_from_data(array_data: Array) -> Array:
	var array = []
	for item in array_data:
		var value = item["value"]
		var type = item["type"]
		if type == TYPE_DICTIONARY:
			value = _get_dictionary_from_data(value)
		elif type == TYPE_ARRAY:
			value = _get_array_from_data(value)
		array.append(value)
	return array


## Recursively get dictionary from dictionary data
func _get_dictionary_from_data(dict_data: Dictionary) -> Dictionary:
	var dict = {}
	for key in dict_data.keys():
		var item = dict_data[key]
		var value = item["value"]
		var type = item["type"]
		if type == TYPE_DICTIONARY:
			value = _get_dictionary_from_data(value)
		elif type == TYPE_ARRAY:
			value = _get_array_from_data(value)
		dict[key] = value
	return dict

#endregion


## Overrides the exported properties on a scene and update export overrides
func _override_exported_properties(scene: Node) -> void:
	var property_list: Array = scene.script.get_script_property_list()
	for prop in _export_overrides.keys():
		if property_list.any(func(p): return p["name"] == prop):
			var value = _export_overrides[prop]["value"]
			# If the property is a collection, get the real value
			if _export_overrides[prop]["type"] == TYPE_DICTIONARY:
				value = _get_dictionary_from_data(value)
			elif _export_overrides[prop]["type"] == TYPE_ARRAY:
				value = _get_array_from_data(value)
			
			scene.set(prop, value)
		else:
			_export_overrides.erase(prop)


## Clear the exported properties from the editor
func _clear_exported_properties() -> void:
	for child in _properties_grid.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()


## Create a new exported property field
func _new_property_field(property_data: Dictionary, value: Variant) -> Control:
	var field_data = SproutyDialogsVariableUtils.new_field_by_type(
			property_data["type"], value, property_data,
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
	
	if type == TYPE_COLOR: # Save color value as a hexadecimal string
		value = value.to_html()
	
	print("\nChanged property: " + name + " to value: " + str(value))
	_set_property_on_dict(name, value, type)
	property_changed.emit(name, value)
	_properties_modified[name] = true

	if not _properties_loaded:
		return # If properties are not loaded, do not create UndoRedo action
	
	# --- UndoRedo -------------------------------------------------------------
	undo_redo.create_action("Edit Portrait Property: " + name.capitalize(), 1)

	undo_redo.add_do_method(SproutyDialogsVariableUtils,
			"set_field_value", field, type, value)
	undo_redo.add_undo_method(SproutyDialogsVariableUtils,
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
@tool
class_name GraphDialogsVariableManager
extends Node

# -----------------------------------------------------------------------------
## Variable Manager
##
## This class manages the variables for the Graph Dialogs plugin.
## It provides methods to get, set, and check variable values.
# -----------------------------------------------------------------------------

## Dictionary to store variable names, types and values
## The dictionary structure is as follows:
## {
##     "variable_name": {
##         "type": 0, # TYPE_NIL
##         "value": null
##     },
##     ...
## }
static var _variables: Dictionary = {}


## Check if a variable exists
static func has_variable(name: String) -> bool:
	return _variables.has(name)


## Get the value of a variable
static func get_variable(name: String) -> Variant:
	if has_variable(name):
		return _variables[name]["value"]
	return null


## Get the type of a variable
static func get_variable_type(name: String) -> int:
	if has_variable(name):
		return _variables[name]["type"]
	return TYPE_NIL


## Set the value of a variable
static func set_variable(name: String, type: int, value: Variant) -> void:
	_variables[name] = {
		"type": type,
		"value": value
	}

## Remove a variable
static func remove_variable(name: String) -> void:
	if has_variable(name):
		_variables.erase(name)


## Load variables from project settings
static func load_from_project_settings() -> Dictionary:
	return GraphDialogsSettings.get_setting("variables")


## Save variables to project settings
static func save_to_project_settings(data: Dictionary) -> void:
	GraphDialogsSettings.set_setting("variables", data)


#region === Variable Type Fields ===============================================

# Returns an OptionButton with all variable types
static func get_types_dropdown() -> OptionButton:
	var dropdown: OptionButton = OptionButton.new()
	dropdown.name = "TypeDropdown"
	var root = EditorInterface.get_base_control()
	dropdown.add_icon_item(root.get_theme_icon("bool", "EditorIcons"), "Bool", TYPE_BOOL)
	dropdown.add_icon_item(root.get_theme_icon("int", "EditorIcons"), "Int", TYPE_INT)
	dropdown.add_icon_item(root.get_theme_icon("float", "EditorIcons"), "Float", TYPE_FLOAT)
	dropdown.add_icon_item(root.get_theme_icon("String", "EditorIcons"), "String", TYPE_STRING)
	dropdown.add_icon_item(root.get_theme_icon("Vector2", "EditorIcons"), "Vector2", TYPE_VECTOR2)
	dropdown.add_icon_item(root.get_theme_icon("Vector3", "EditorIcons"), "Vector3", TYPE_VECTOR3)
	dropdown.add_icon_item(root.get_theme_icon("Vector4", "EditorIcons"), "Vector4", TYPE_VECTOR4)
	dropdown.add_icon_item(root.get_theme_icon("Color", "EditorIcons"), "Color", TYPE_COLOR)

	# ----------------------------------
	# Add more types as needed here (!)
	# ----------------------------------

	return dropdown


## Returns a Control node for the variable type field
static func get_field_by_type(type: int, on_value_changed: Callable) -> Dictionary:
	var field = null
	var default_value = null
	match type:
		TYPE_BOOL:
			field = CheckBox.new()
			field.toggled.connect(on_value_changed)
			default_value = false
		TYPE_INT:
			field = SpinBox.new()
			field.step = 1
			field.allow_greater = true
			field.allow_lesser = true
			field.value_changed.connect(on_value_changed)
			default_value = field.value
		TYPE_FLOAT:
			field = SpinBox.new()
			field.step = 0.01
			field.allow_greater = true
			field.allow_lesser = true
			field.value_changed.connect(on_value_changed)
			default_value = field.value
		TYPE_STRING:
			field = LineEdit.new()
			field.text_changed.connect(on_value_changed)
			default_value = field.text
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			var vector_n := int(type_string(type)[-1])
			var components_names = ["x", "y", "z", "w"]
			field = HFlowContainer.new()
			# Create the fields for each component of the vector
			for i in range(0, vector_n):
				var label = Label.new()
				label.text = components_names[i]
				field.add_child(label)
				var x_field = SpinBox.new()
				x_field.step = 0.01
				x_field.allow_greater = true
				x_field.allow_lesser = true
				field.add_child(x_field)
				x_field.value_changed.connect(func():
					var values = []
					for child in field.get_children():
						if child is SpinBox:
							values.append(child.value)
					on_value_changed.call(values)
				)
			default_value = Vector2.ZERO if type == TYPE_VECTOR2 \
					else Vector3.ZERO if type == TYPE_VECTOR3 else Vector4.ZERO
		TYPE_COLOR:
			field = ColorPickerButton.new()
			field.color_changed.connect(on_value_changed)
			default_value = field.color
		
		# ----------------------------------
		# Add more types as needed here (!)
		# ----------------------------------

		_:
			field = LineEdit.new() # Default to LineEdit for unsupported types
			field.text_changed.connect(on_value_changed)
			default_value = field.text
	return {
		"field": field,
		"default_value": default_value
	}


## Sets the value in the given field based on its type
static func set_field_value(field: Control, type: int, value: Variant) -> void:
	match type:
		TYPE_BOOL:
			if field is CheckBox:
				field.button_pressed = bool(value)
		TYPE_INT, TYPE_FLOAT:
			if field is SpinBox:
				field.value = float(value)
		TYPE_STRING:
			if field is LineEdit:
				field.text = str(value)
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			var vector_n := int(type_string(type)[-1])
			if field is HFlowContainer:
				var i = 0
				for child in field.get_children():
					if child is SpinBox and i < vector_n:
						child.value = float(value[i])
						i += 1
		TYPE_COLOR:
			if field is ColorPickerButton:
				field.color = Color(value)
		
		# ----------------------------------
		# Add more types as needed here (!)
		# ----------------------------------

		_:
			if field is LineEdit:
				field.text = str(value)

#endregion
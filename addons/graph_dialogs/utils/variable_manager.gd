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
## Also supports groups of variables, which can contain other variables.
## The dictionary structure is as follows:
## {
##     "variable_name_1": {
##         "type": 0, # TYPE_NIL
##         "value": null
##     },
##     "group": {
##         "color": Color(1, 1, 1),
##         "variables": {
##             "variable_name_2": {
##                 "type": 0, # TYPE_NIL
##                 "value": null
##             },
##             ...
##         }
##     },
##     ...
## }
static var _variables: Dictionary = {}


## Returns variables as a dictionary.
static func get_variables() -> Dictionary:
	if _variables.is_empty():
		load_variables() # Load variables if not already loaded
	return _variables


## Get the type and value of a variable.
## If the variable does not exist, it returns null.
static func get_variable(name: String, group: Dictionary = _variables) -> Variant:
	for key in group.keys():
		if key == name:
			return group[key]
		if group[key].has("variables"): # Recursively check in groups
			var variable = get_variable(name, group[key].variables)
			if variable:
				return variable
	return null


## Get all variables of a specific type.
## If no variables of the specified type are found, it returns an empty dictionary.
static func get_variables_by_type(type: int, group: Dictionary = _variables) -> Dictionary:
	var result: Dictionary = {}
	for key in group.keys():
		var variable = group[key]
		if variable.has("variables"): # Recursively check in groups
			var sub_variables = get_variables_by_type(type, variable.variables)
			if not sub_variables.is_empty():
				result.merge(sub_variables)
		elif variable.type == type:
			result[key] = variable
	return result


## Set a variable in the Variables Manager.
## If the variable does not exist, it will be created.
## If the variable exists, it will be updated.
static func set_variable(name: String, type: int, value: Variant) -> void:
	var variable = get_variable(name)
	if not variable: # If variable does not exist, create it
		_variables[name] = {
			"type": type,
			"value": value
		}
	else: # Update existing variable
		variable.type = type
		variable.value = value
	save_variables(_variables) # Save changes to project settings


## Update the value of a variable.
## If variable is not found in the Variables Manager, try to find it in
## global variables and update it.
static func update_variable(name: String, type: int, value: Variant) -> void:
	pass


## Check if a variable exists
static func has_variable(name: String, group: Dictionary = _variables) -> bool:
	return get_variable(name, group) != null


## Load variables from project settings
static func load_variables() -> void:
	_variables = GraphDialogsSettings.get_setting("variables")


## Save variables to project settings
static func save_variables(data: Dictionary) -> void:
	GraphDialogsSettings.set_setting("variables", data)
	_variables = data


## Replaces all variables ({}) in a text with their corresponding values
static func parse_variables(text: String) -> String:
	if not "{" in text:
		return text # No variables to parse
	
	# Find all variables in the format {variable_name}
	var regex := RegEx.new()
	regex.compile("{([^{}]+)}")
	var results = regex.search_all(text)
	results = results.map(func(val): return val.get_string(1))

	if not results.is_empty():
		for var_name in results:
			var variable = get_variable(var_name)
			if variable:
				if variable.type == TYPE_STRING: # Recursively parse variables
					variable.value = parse_variables(variable.value)
				elif variable.type == TYPE_COLOR and variable.value is Color:
					variable.value = variable.value.to_html() # Convert to Hex string
				text = text.replace("{" + var_name + "}", str(variable.value))
			else:
				printerr("[Graph Dialogs] Variable '" + var_name + "' not found. " +
					"Please check if the variable exists in the Variables Manager.")
	return text


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
			field = HBoxContainer.new()
			var line_edit = LineEdit.new()
			line_edit.name = "TextEdit"
			line_edit.set_h_size_flags(Control.SIZE_EXPAND_FILL)
			line_edit.placeholder_text = "Enter text here..."
			line_edit.text_changed.connect(on_value_changed)
			field.add_child(line_edit)
			var button = Button.new()
			button.name = "ExpandButton"
			button.icon = EditorInterface.get_base_control().\
					get_theme_icon("DistractionFree", "EditorIcons")
			field.add_child(button)
			default_value = line_edit.text
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			var vector_n := int(type_string(type)[-1])
			var components_names = ["x", "y", "z", "w"]
			field = HFlowContainer.new()

			for i in range(0, vector_n):
				# Create a container for each component
				var container = HBoxContainer.new()
				container.name = str(components_names[i]) # x, y, z, w
				container.set_h_size_flags(Control.SIZE_EXPAND_FILL)
				field.add_child(container)

				# Add a label and a SpinBox for each component
				var label = Label.new()
				label.text = components_names[i]
				container.add_child(label)

				var component_field = SpinBox.new()
				component_field.name = "Field"
				component_field.step = 0.01
				component_field.allow_greater = true
				component_field.allow_lesser = true
				container.add_child(component_field)

				default_value = Vector2.ZERO if type == TYPE_VECTOR2 \
					else Vector3.ZERO if type == TYPE_VECTOR3 else Vector4.ZERO
				
				component_field.value_changed.connect(func(value):
					var vector_value = default_value
					for j in range(0, vector_n):
						if field.get_child_count() > j:
							var component = field.get_child(j).get_node("Field")
							vector_value[j] = component.value
					on_value_changed.call(vector_value)
				)
		TYPE_COLOR:
			field = ColorPickerButton.new()
			field.color_changed.connect(on_value_changed)
			default_value = field.color.to_html()
		
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
			if field is HBoxContainer:
				var text_edit = field.get_node("TextEdit")
				if text_edit is LineEdit:
					text_edit.text = str(value)
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			var vector_n := int(type_string(type)[-1])
			if field is HFlowContainer:
				for i in range(0, vector_n):
					if field.get_child_count() > i:
						var component = field.get_child(i).get_node("Field")
						if component is SpinBox:
							component.value = float(value[i])
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

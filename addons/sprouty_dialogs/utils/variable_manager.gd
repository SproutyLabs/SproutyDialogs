@tool
class_name EditorSproutyDialogsVariableManager
extends Node

# -----------------------------------------------------------------------------
# Sprouty Dialogs Variable Manager
# -----------------------------------------------------------------------------
## This class manages the variables in the Sprouty Dialogs plugin.
## It provides methods to get, set, check, load and save variables.
##
## Also provides methods to parse variables in strings, get the UI fields and
## components needed to edit them in the editor, and to get the assignment
## and comparison operators available for each variable type.
# -----------------------------------------------------------------------------

## Assignment operators for variables
enum ASSIGN_OPS {
	ASSIGN, ## Direct assignment operator (=)
	ADD_ASSIGN, ## Addition assignment operator (+=)
	SUB_ASSIGN, ## Subtraction assignment operator (-=)
	MUL_ASSIGN, ## Multiplication assignment operator (*=)
	DIV_ASSIGN, ## Division assignment operator (/=)
	EXP_ASSIGN, ## Exponentiation assignment operator (**=)
	MOD_ASSIGN, ## Modulus assignment operator (%=)
}

## Comparison operators for variables
enum COMPARISON_OPS {
	EQUAL, ## Equality operator (==)
	NOT_EQUAL, ## Inequality operator (!=)
	LESS_THAN, ## Less than operator (<)
	GREATER_THAN, ## Greater than operator (>)
	LESS_EQUAL, ## Less than or equal to operator (<=)
	GREATER_EQUAL ## Greater than or equal to operator (>=)
}

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
## Variable icon
static var _variable_icon = preload("res://addons/sprouty_dialogs/editor/icons/variable.svg")
## Reference to the root node of the scene tree
## This is used to access autoloads and other global nodes.
## It is set in the _ready() function of the SproutyDialogsManager.
static var _root_reference: Node = null


## Sets the root reference for the Variable Manager.
## This is used to access autoloads and other global nodes.
## It should be called ONLY in the _ready() function of the SproutyDialogsManager.
static func set_root_reference(root: Node) -> void:
	_root_reference = root


## Returns variables as a dictionary.
## If the variables are not loaded, it will load them from project settings.
static func get_variables() -> Dictionary:
	if _variables.is_empty():
		load_variables() # Load variables if not already loaded
	return _variables


## Returns a list of the variable names.
## If a type is specified, it returns only the variables of that type.
## If no type is specified, it returns all variables.
## If no variables are found, it returns an empty array.
static func get_variable_list(type: int = -1, group: Dictionary = _variables) -> Array:
	var variable_list: Array = []
	for key in group.keys():
		if group[key].has("variables"): # Recursively check in groups
			var sub_variables = get_variable_list(type, group[key].variables)
			for sub_key in sub_variables:
				variable_list.append(key + "/" + sub_key)
		# Check if the variable type matches or if no type is specified
		elif type == -1 or group[key].type == type:
			variable_list.append(key)
	return variable_list


## Get a variable from the Variables Manager or from the autoloads.
## If the variable is found, it returns a dictionary with the variable name, type and value
## If the variable does not exist, it returns null.
static func get_variable(name: String) -> Variant:
	if _variables.has(name): # If the variable is a directly in the dictionary
		var variable = _variables[name]
		return {
			"name": name,
			"type": variable.type,
			"value": variable.value
		}
	elif "/" in name: # If the variable is inside a group
		var parts = name.split("/")
		var current_group = _variables
		for part in parts:
			if current_group.has(part):
				if current_group[part].has("variables"): # Check inside
					current_group = current_group[part].variables
				else: # Variable found
					return {
						"name": part,
						"type": current_group[part].type,
						"value": current_group[part].value
					}
	elif "." in name: # If the variable is in an autoload
		var from = name.get_slice(".", 0)
		var autoloads = get_autoloads()
		if autoloads.has(from):
			var variable_name = name.get_slice(".", 1)
			var variable_value = autoloads[from].get(variable_name)
			return {
			"name": variable_name,
			"type": typeof(variable_value),
			"value": variable_value
		}
	return null
	

## Set or update a variable in the Variables Manager or in the autoloads.
## The variable must already exist in the Variables Manager or in the autoloads.
static func set_variable(name: String, value: Variant) -> void:
	if _variables.has(name): # If the variable is a directly in the dictionary
		_variables[name].value = value
		return
	elif "/" in name: # If the variable is inside a group
		var parts = name.split("/")
		var current_group = _variables
		for part in parts:
			if current_group.has(part):
				if current_group[part].has("variables"): # Check inside
					current_group = current_group[part].variables
				else: # Variable found
					current_group[part].value = value
					return
	elif "." in name: # If the variable is in an autoload
		var from = name.get_slice(".", 0)
		var autoloads = get_autoloads()
		if autoloads.has(from):
			var variable_name = name.get_slice(".", 1)
			if autoloads[from].get(variable_name):
				autoloads[from].set(variable_name, value)
				return
			else:
				printerr("[Sprouty Dialogs] Cannot set variable '" + variable_name +
						"'. Variable not found in autoload '" + from + "'.")
				return
	
	printerr("[Sprouty Dialogs] Cannot set variable '" + name + "'. Variable not found.")


## Check if a variable exists
static func has_variable(name: String, group: Dictionary = _variables) -> bool:
	return get_variable(name) != null


## Load variables from project settings
static func load_variables() -> void:
	_variables = EditorSproutyDialogsSettingsManager.get_setting("variables")


## Save variables to project settings
static func save_variables(data: Dictionary) -> void:
	EditorSproutyDialogsSettingsManager.set_setting("variables", data)
	_variables = data


## Replaces all variables ({}) in a text with their corresponding values
static func parse_variables(text: String, ignore_error: bool = false) -> String:
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
			elif not ignore_error:
				printerr("[Sprouty Dialogs] Cannot parse variable {" + var_name + "} not found. " +
					"Please check if the variable exists in the Variables Manager or in the autoloads.")
	return text


## Returns a dictionary with the autoloads from a given scene tree.
static func get_autoloads() -> Dictionary:
	var autoloads := {}
	if _root_reference: # If root reference is set, get autoloads from it
		for node: Node in _root_reference.get_children():
			autoloads[node.name] = node
		return autoloads
	return {}


#region === Variable Type Fields ===============================================

# Returns an OptionButton with all variable types
static func get_types_dropdown(label: bool = true, include_var: bool = false) -> OptionButton:
	var dropdown: OptionButton = OptionButton.new()
	dropdown.name = "TypeDropdown"
	dropdown.tooltip_text = "Select variable type"
	dropdown.mouse_filter = Control.MOUSE_FILTER_PASS

	var root = EditorInterface.get_base_control()
	if include_var: # Add variable as a type option
		dropdown.add_icon_item(_variable_icon, "Variable" if label else "", TYPE_NIL)
	dropdown.add_icon_item(root.get_theme_icon("bool", "EditorIcons"), "Bool" if label else "", TYPE_BOOL)
	dropdown.add_icon_item(root.get_theme_icon("int", "EditorIcons"), "Int" if label else "", TYPE_INT)
	dropdown.add_icon_item(root.get_theme_icon("float", "EditorIcons"), "Float" if label else "", TYPE_FLOAT)
	dropdown.add_icon_item(root.get_theme_icon("String", "EditorIcons"), "String" if label else "", TYPE_STRING)
	dropdown.add_icon_item(root.get_theme_icon("Vector2", "EditorIcons"), "Vector2" if label else "", TYPE_VECTOR2)
	dropdown.add_icon_item(root.get_theme_icon("Vector3", "EditorIcons"), "Vector3" if label else "", TYPE_VECTOR3)
	dropdown.add_icon_item(root.get_theme_icon("Vector4", "EditorIcons"), "Vector4" if label else "", TYPE_VECTOR4)
	dropdown.add_icon_item(root.get_theme_icon("Color", "EditorIcons"), "Color" if label else "", TYPE_COLOR)

	# ----------------------------------
	# Add more types as needed here (!)
	# ----------------------------------

	return dropdown


## Returns a Control node for the variable type field
static func get_field_by_type(type: int, on_value_changed: Callable) -> Dictionary:
	var field = null
	var default_value = null
	match type:
		TYPE_NIL: # Variable field
			field = EditorSproutyDialogsComboBox.new()
			var popup = PopupMenu.new()
			popup.name = "DropdownPopup"
			field.add_child(popup)
			field.set_placeholder("Variable name...")
			field.set_options(get_variable_list())
			field.option_selected.connect(on_value_changed)
			default_value = ""
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
			line_edit.placeholder_text = "Write text here..."
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
			field.custom_minimum_size = Vector2(60, 60)
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
		TYPE_NIL:
			if field is EditorSproutyDialogsComboBox:
				field.set_value(value) # Set the variable name
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

#region === Variable Type Operators ============================================

## Returns a list of assignment operators by type
static func get_assignment_operators(type: int) -> Dictionary:
	match type:
		TYPE_BOOL:
			return { # Boolean assignment
				"=": ASSIGN_OPS.ASSIGN
				}
		TYPE_INT, TYPE_FLOAT:
			return { # Arithmetic operators
				"=": ASSIGN_OPS.ASSIGN,
				"+=": ASSIGN_OPS.ADD_ASSIGN,
				"-=": ASSIGN_OPS.SUB_ASSIGN,
				"*=": ASSIGN_OPS.MUL_ASSIGN,
				"/=": ASSIGN_OPS.DIV_ASSIGN,
				"**=": ASSIGN_OPS.EXP_ASSIGN,
				"%=": ASSIGN_OPS.MOD_ASSIGN
			}
		TYPE_STRING:
			return { # String assignment and concatenation
				"=": ASSIGN_OPS.ASSIGN,
				"+=": ASSIGN_OPS.ADD_ASSIGN,
			}
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			return { # Vector arithmetic operators
				"=": ASSIGN_OPS.ASSIGN,
				"+=": ASSIGN_OPS.ADD_ASSIGN,
				"-=": ASSIGN_OPS.SUB_ASSIGN,
				"*=": ASSIGN_OPS.MUL_ASSIGN,
				"/=": ASSIGN_OPS.DIV_ASSIGN,
			}
		TYPE_COLOR:
			return { # Color arithmetic operators
				"=": ASSIGN_OPS.ASSIGN,
				"+=": ASSIGN_OPS.ADD_ASSIGN,
				"-=": ASSIGN_OPS.SUB_ASSIGN,
			}
		_:
			return { # Default to assignment for other types
				"=": ASSIGN_OPS.ASSIGN
			}


## Returns the comparison operators as a dictionary
static func get_comparison_operators() -> Dictionary:
	return {
		"==": COMPARISON_OPS.EQUAL,
		"!=": COMPARISON_OPS.NOT_EQUAL,
		"<": COMPARISON_OPS.LESS_THAN,
		">": COMPARISON_OPS.GREATER_THAN,
		"<=": COMPARISON_OPS.LESS_EQUAL,
		">=": COMPARISON_OPS.GREATER_EQUAL
	}


## Returns the value resulting from an assignment operation
## This function is used to calculate the new value of a variable after an assignment operation.
static func get_assignment_result(type: int, operator: int, value: Variant, new_value: Variant) -> Variant:
	match operator:
		ASSIGN_OPS.ASSIGN: # Direct assignment
			return new_value
		ASSIGN_OPS.ADD_ASSIGN: # Addition
			if type == TYPE_STRING:
				return str(value) + str(new_value)
			elif type == TYPE_COLOR:
				return value + Color(new_value)
			else:
				return value + new_value
		ASSIGN_OPS.SUB_ASSIGN: # Subtraction
			if type == TYPE_COLOR:
				return value - Color(new_value)
			else:
				return value - new_value
		ASSIGN_OPS.MUL_ASSIGN: # Multiplication
			return value * new_value
		ASSIGN_OPS.DIV_ASSIGN: # Division
			return value / new_value
		ASSIGN_OPS.EXP_ASSIGN: # Exponentiation
			return value ** new_value
		ASSIGN_OPS.MOD_ASSIGN: # Modulus
			if type == TYPE_FLOAT:
				return fmod(value, new_value)
			else:
				return value % new_value
		_: # Unsupported operator, return the new value as is
			return new_value


## Returns the result of comparing two values based on the specified operator.
static func get_comparison_result(first_type: int, first_value: Variant,
		second_type: int, second_value: Variant, operator: int) -> Variant:
	# Get the variable values if any is a variable
	if first_type == TYPE_NIL:
		var variable = get_variable(first_value)
		if variable:
			first_value = variable.value
			first_type = variable.type
		else:
			printerr("[Sprouty Dialogs] Cannot check condition. Variable '" + str(first_value) + "' not found. " +
				"Please check if the variable exists in the Variables Manager or in the autoloads.")
			return null
	if second_type == TYPE_NIL:
		var variable = get_variable(second_value)
		if variable:
			second_value = variable.value
			second_type = variable.type
		else:
			printerr("[Sprouty Dialogs] Cannot check condition. Variable '" + str(second_value) + "' not found. " +
				"Please check if the variable exists in the Variables Manager or in the autoloads.")
			return null

	if first_type != second_type: # If types do not match, cannot compare
		printerr("[Sprouty Dialogs] Cannot compare variables of type '" +
			type_string(first_type) + "' and '" + type_string(second_type) + "'.")
		printerr("Values '" + str(first_value) + "' and '" + str(second_value) + "' are not comparable.")
		return null

	match operator:
		COMPARISON_OPS.EQUAL:
			return first_value == second_value
		COMPARISON_OPS.NOT_EQUAL:
			return first_value != second_value
		COMPARISON_OPS.LESS_THAN:
			return first_value < second_value
		COMPARISON_OPS.GREATER_THAN:
			return first_value > second_value
		COMPARISON_OPS.LESS_EQUAL:
			return first_value <= second_value
		COMPARISON_OPS.GREATER_EQUAL:
			return first_value >= second_value
		_:
			printerr("[Sprouty Dialogs] Unsupported comparison operator: " + str(operator))
			return false

#endregion

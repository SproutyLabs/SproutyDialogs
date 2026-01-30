@tool
class_name SproutyDialogsVariableManager
extends Node

# -----------------------------------------------------------------------------
# Sprouty Dialogs Variable Manager
# -----------------------------------------------------------------------------
## This class manages the variables in the Sprouty Dialogs plugin.
## It provides methods to get, set, check, parse variables in strings
## and get assigment and comparision operations results.
# -----------------------------------------------------------------------------

## Dictionary to store variable names, types and values
## Also supports groups of variables, which can contain other variables.
## The dictionary structure is as follows:
## {
##     "variable_name_1": {
##		   "index": 0,
##         "type": 0, # TYPE_NIL
##         "value": null
##         "metadata": {}
##     },
##     "group": {
##         "index": 1,
##         "color": Color(1, 1, 1),
##         "variables": {
##             "variable_name_2": {
##                 "index": 0,
##                 "type": 0, # TYPE_NIL
##                 "value": null
##                 "metadata": {}
##             },
##             ...
##         }
##     },
##     ...
## }
var _variables: Dictionary = {}


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		get_variables_data() # Load variables in game


## Returns all the variables data as a dictionary.
## If the variables are not loaded, it will load them from project settings.
func get_variables_data() -> Dictionary:
	if _variables.is_empty():
		_variables = SproutyDialogsSettingsManager.get_setting("variables").duplicate(true)
	return _variables


## Get the data of a variable defined in the variable editor or from the autoloads.
## If the variable is found, it returns a dictionary with its data.
## If the variable does not exist, it returns an empty dictionary.
func get_variable_data(name: String) -> Dictionary:
	if _variables.has(name): # If the variable is a directly in the dictionary
		var variable = _variables[name]
		if variable.has("variables"):
			return {} # Is a group, not variable
		return {
			"index": variable.index,
			"name": name,
			"type": variable.type,
			"value": variable.value,
			"metadata": variable.metadata
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
						"index": current_group[part].index,
						"name": part,
						"type": current_group[part].type,
						"value": current_group[part].value,
						"metadata": current_group[part].metadata
					}
	elif "." in name: # If the variable is in an autoload
		var from = name.get_slice(".", 0)
		var autoloads = _get_autoloads()
		if autoloads.has(from):
			var variable_name = name.get_slice(".", 1)
			var prop = autoloads[from].script.get_script_property_list().find(
				func(p): return p["name"] == variable_name
			)
			return {
			"index": 0,
			"name": variable_name,
			"type": prop["type"],
			"value": prop["value"],
			"metadata": {
				"hint": prop["hint"],
				"hint_string": prop["hint_string"]
			}
		}
	return {}


## Get the value of a variable defined in the variable editor or from the autoloads.
## If the variable is found, it returns a dictionary with its data.
## If the variable does not exist, it returns null.
func get_variable(name: String) -> Variant:
	var var_data = get_variable_data(name)
	return var_data.value if not var_data.is_empty() else null


## Set or update the value of a variable defined in the variable editor or from the autoloads.
func set_variable(name: String, value: Variant) -> void:
	if _variables.has(name): # If the variable is directly in the dictionary
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
		var autoloads = _get_autoloads()
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


## Check if a variable exists in the variable editor or in the autoloads.
func has_variable(name: String) -> bool:
	return not get_variable_data(name).is_empty()


## Retuns a list with the names of the variables in a group.
## If no group is especified, return the top-level variables.
func get_variables_in_group(group_name: String) -> Array:
	if group_name == "":
		var names := []
		for key in _variables.keys():
			var child = _variables[key]
			if child.has("variables"):
				continue # Skip entries that are groups
			names.append(key)
		return names
	# Support nested groups separated by '/'
	var parts = group_name.split("/")
	var current_group = _variables
	for i in range(parts.size()):
		var part = parts[i]
		if not current_group.has(part):
			printerr("[Sprouty Dialogs] Cannot get variables in group '" \
				+ group_name + "'. '" + parts[i] + "' group not found.")
			return []
		var child = current_group[part]
		if child.has("variables"):
			# If this is the last part, return the variable names
			if i == parts.size() - 1:
				var names := []
				for key in child.variables.keys():
					var _var = child.variables[key]
					if _var.has("variables"):
						continue # Skip entries that are groups
					names.append(key)
				return names
			# Otherwise descend into the group's variables dictionary
			current_group = child.variables
		else: # This part is not a group
			printerr("[Sprouty Dialogs] Cannot get variables in group '" \
				+ group_name + "'. '" + parts[i] + "' is a variable not a group.")
			return []
	# Fallback, no group found
	printerr("[Sprouty Dialogs] Cannot get variables from group '" + group_name \
		+"'. Group not found, please check the variable editor.")
	return []


## Check if a variable is in a given group.
func is_variable_in_group(variable_name: String, group_name: String) -> bool:
	var vars = get_variables_in_group(group_name)
	return vars.has(variable_name)


## Reset a variable to its initial value.
## If no variable is specified, reset all variables.
## This method only resets variables defined in the variable editor,
## you cannot reset variables from autoloads here.
func reset_variable(name: String = "") -> void:
	var vars_data = SproutyDialogsSettingsManager.get_setting("variables")
	if name == "": # Reset all variables
		_variables = vars_data
		return
	
	if _variables.has(name): # If the variable is directly in the dictionary
		_variables[name].value = vars_data.value
		return
	elif "/" in name: # If the variable is inside a group
		var parts = name.split("/")
		var current_var_group = _variables
		var current_data_group = vars_data
		for part in parts:
			if current_var_group.has(part) and current_data_group.has(part):
				if current_var_group[part].has("variables") \
						and current_data_group[part].has("variables"):
					current_var_group = current_var_group[part].variables
					current_data_group = current_data_group[part].variables
				else: # Variable found
					current_var_group[part].value = current_data_group[part].value
					return

	printerr("[Sprouty Dialogs] Cannot reset variable '" + name + "'. Variable not found.")


#region === Parse Variables ====================================================

## Replaces all variables ({}) in a text with their corresponding values.
func parse_variables(text: String, ignore_error: bool = false) -> String:
	if not "{" in text:
		return text # No variables to parse
	
	if Engine.is_editor_hint(): # Get variables from project settings
		_variables = SproutyDialogsSettingsManager.get_setting("variables")
	
	# Find all variables in the format {variable_name}
	var regex := RegEx.new()
	regex.compile("{([^{}]*)}")
	var results = regex.search_all(text)
	results = results.map(func(val): return val.get_string(1))
	
	var remains = results.duplicate()
	if not results.is_empty():
		for var_name in results:
			var parsed_variable = _get_parsed_variable(var_name, ignore_error)
			if parsed_variable:
				text = text.replace("{" + var_name + "}", str(parsed_variable.value))
				remains.erase(var_name)
				
		# Check if there are still unparsed variables
		var post_results = regex.search_all(text)
		post_results = post_results.map(
			func(val): return val.get_string(1)).filter(
				func(val): return not remains.has(val)
			)

		if not post_results.is_empty(): # Recursively parse remaining variables
			text = parse_variables(text, ignore_error)
	return text


## Gets the value of a variable or expression.
## Returns a dictionary with the variable name, type, value and metadata.
## If the variable does not exist or the expression fails, it returns null.
func _get_parsed_variable(var_name: String, ignore_error: bool = false,
		only_parse_var: bool = false) -> Variant:
	var variable = get_variable_data(var_name)
	if not variable.is_empty():
		if variable.type == TYPE_STRING:
			# If the variable is an expression, execute it
			if variable.metadata.has("hint") and \
					variable.metadata["hint"] == PROPERTY_HINT_EXPRESSION:
				var result = _execute_expression(variable.value, ignore_error)
				
				if not result: # Error evaluating expression
					if not ignore_error:
						printerr("[Sprouty Dialogs] Error evaluating expression of variable '" +
							var_name + "': " + str(variable.value))
					return null
				variable.value = result
				variable.type = typeof(result)
				variable.metadata = {}
			else:
				# Recursively parse variables in the string
				variable.value = parse_variables(variable.value)
		
		elif variable.type == TYPE_COLOR and variable.value is Color:
			variable.value = variable.value.to_html() # Convert to Hex string
	
	elif not only_parse_var: # Try to execute as expression
		var result = _execute_expression(var_name, ignore_error)
		if not result: # Error evaluating expression
			if not ignore_error:
				printerr("[Sprouty Dialogs] Cannot found variable or parse {"
						+ var_name + "} as expression. ")
			return null
		variable = {
			"index": 0,
			"name": var_name,
			"type": typeof(result),
			"value": result,
			"metadata": {}
		}
	else: # Variable not found
		if not ignore_error:
			printerr("[Sprouty Dialogs] Cannot parse variable {" + var_name + "} not found. " +
				"Please check if the variable exists in the Variables Manager or in the autoloads.")
		return null
	return variable


## Executes a expression with variables parsed.
## Returns the result of the expression.
func _execute_expression(command: String, ignore_error: bool = false) -> Variant:
	var parsed_command = parse_variables(command, true)
	var autoloads = _get_autoloads()
	var expression = Expression.new()
	var error = expression.parse(parsed_command, autoloads.keys())
	if error != OK:
		if not ignore_error:
			printerr("[Sprouty Dialogs] Error parsing expression: " + expression.get_error_text())
		return null
	var result = expression.execute(autoloads.values(), self , not ignore_error)
	if expression.has_execute_failed():
		if not ignore_error:
			printerr("[Sprouty Dialogs] Error executing expression: " + expression.get_error_text())
		return null
	else: # Successful execution
		return result


## Returns a dictionary with the autoloads from a given scene tree.
func _get_autoloads() -> Dictionary:
	var autoloads := {}
	for node in get_tree().root.get_children():
		autoloads[node.name] = node
	return autoloads

#endregion

#region === Assignment & Conditions ============================================

## Returns the value resulting from an assignment operation.
static func get_assignment_result(type: int, operator: int, value: Variant, new_value: Variant) -> Variant:
	var assign_enum = SproutyDialogsVariableUtils.ASSIGN_OPS
	match operator:
		assign_enum.ASSIGN: # Direct assignment
			return new_value
		assign_enum.ADD_ASSIGN: # Addition
			if type == TYPE_STRING:
				return str(value) + str(new_value)
			elif type == TYPE_COLOR:
				return value + Color(new_value)
			else:
				return value + new_value
		assign_enum.SUB_ASSIGN: # Subtraction
			if type == TYPE_COLOR:
				return value - Color(new_value)
			else:
				return value - new_value
		assign_enum.MUL_ASSIGN: # Multiplication
			return value * new_value
		assign_enum.DIV_ASSIGN: # Division
			return value / new_value
		assign_enum.EXP_ASSIGN: # Exponentiation
			return value ** new_value
		assign_enum.MOD_ASSIGN: # Modulus
			if type == TYPE_FLOAT:
				return fmod(value, new_value)
			else:
				return value % new_value
		_: # Unsupported operator, return the new value as is
			return new_value


## Returns the result of comparing two values based on the specified operator.
func get_comparison_result(first_var: Dictionary, second_var: Dictionary,
		operator: int) -> Variant:
	# Get the variable values if any is a variable
	first_var = _parse_condition_value(first_var)
	second_var = _parse_condition_value(second_var)
	if first_var == null or second_var == null:
		return null

	# If both variables are not numeric types, ensure they are of the same type
	var numeric_types = [TYPE_INT, TYPE_FLOAT]
	if not (first_var.type in numeric_types and second_var.type in numeric_types):
		if first_var.type != second_var.type: # If types do not match, cannot compare
			printerr("[Sprouty Dialogs] Cannot compare variables of type '" +
				type_string(first_var.type) + "' and '" + type_string(second_var.type) + "'." \
				+" Values '" + str(first_var.value) + "' and '" + str(second_var.value) + "' are not comparable.")
			return null

	match operator:
		OP_EQUAL:
			return first_var.value == second_var.value
		OP_NOT_EQUAL:
			return first_var.value != second_var.value
		OP_LESS:
			return first_var.value < second_var.value
		OP_GREATER:
			return first_var.value > second_var.value
		OP_LESS_EQUAL:
			return first_var.value <= second_var.value
		OP_GREATER_EQUAL:
			return first_var.value >= second_var.value
		_:
			printerr("[Sprouty Dialogs] Unsupported comparison operator: " + str(operator))
			return false


## Parses a variable data dictionary to get its actual value for condition checking.
func _parse_condition_value(var_data: Dictionary) -> Variant:
	var parse_var = var_data
	match var_data.type:
		TYPE_STRING:
			# Expression type
			if var_data.metadata.has("hint") and \
					var_data.metadata["hint"] == PROPERTY_HINT_EXPRESSION:
				var result = _execute_expression(var_data.value)
				if result != null:
					parse_var.value = result
					parse_var.type = typeof(result)
				else:
					printerr("[Sprouty Dialogs] Cannot check condition. Error evaluating expression: " +
						str(var_data.value))
					return null
		40: # Variable type
			var variable = _get_parsed_variable(var_data.value, true, true)
			if variable:
				parse_var.value = variable.value
				parse_var.type = variable.type
				parse_var.metadata = variable.metadata
			else:
				printerr("[Sprouty Dialogs] Cannot check condition. Variable '" + str(var_data.value) + "' not found. " +
					"Please check if the variable exists in the Variables Manager or in the autoloads.")
				return null
		_:
			return var_data
	return parse_var

#endregion

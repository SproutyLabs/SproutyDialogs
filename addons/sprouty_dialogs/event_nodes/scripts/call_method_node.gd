@tool
extends SproutyDialogsBaseNode

# -----------------------------------------------------------------------------
# Sprouty Dialogs Call Method Node
# -----------------------------------------------------------------------------
## Node to call a method from an autoload between dialog nodes.
# -----------------------------------------------------------------------------

## Autoloads dropdown
@onready var _autoloads_dropdown: OptionButton = %AutoloadsDropdown
## Method combo box
@onready var _method_combo_box: EditorSproutyDialogsComboBox = %MethodComboBox
## Parameters array field
@onready var _parameters_field: EditorSproutyDialogsArrayField = %ParametersField

## Parameters data of the selected autoload methods
var _methods_params: Dictionary = {}

## Previous selected autoload index (for UndoRedo)
var _previous_autoload_index: int = 0
## Previous selected method (for UndoRedo)
var _previous_method: String = ""
## Previous parameters (for UndoRedo)
var _previous_params: Array = []


func _ready():
	super ()
	_autoloads_dropdown.item_selected.connect(_on_autoload_selected)
	_method_combo_box.option_selected.connect(_on_method_selected)
	_parameters_field.item_changed.connect(_on_parameter_changed)
	_parameters_field.modified.connect(modified.emit.bind(true))
	_parameters_field.resized.connect(func(): size.y=0.0)
	_parameters_field.disable_field(true)
	_method_combo_box.editable = false
	_set_autoloads_dropdown()


#region === Node Data ==========================================================

func get_data() -> Dictionary:
	var dict := {}
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"autoload": _autoloads_dropdown.get_item_text(_autoloads_dropdown.selected),
		"method": _method_combo_box.get_value(),
		"parameters": _parameters_field.get_array(),
		"to_node": get_output_connections(),
		"offset": position_offset,
		"size": size
	}
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	to_node = dict["to_node"]
	position_offset = dict["offset"]
	size = dict["size"]

	_set_autoloads_dropdown(dict["autoload"])
	_set_method_combo_box(dict["autoload"])
	_method_combo_box.set_value(dict["method"])
	_parameters_field.set_array(dict["parameters"])

	_previous_autoload_index = _autoloads_dropdown.selected
	_previous_method = dict["method"]
	_previous_params = dict["parameters"]

	if not dict["parameters"].is_empty():
		_parameters_field.disable_field(false)

#endregion


## Setup autoloads options on the dropdown
func _set_autoloads_dropdown(selected: String = "") -> void:
	_autoloads_dropdown.clear()
	var autoloads = ["(No one)"]
	for prop in ProjectSettings.get_property_list():
		if prop.name.begins_with("autoload/"):
			autoloads.append(prop.name.replace("autoload/", ""))
	
	for autoload in autoloads:
		_autoloads_dropdown.add_icon_item(node_icon, autoload)
		if autoload == selected:
			_autoloads_dropdown.select(_autoloads_dropdown.item_count - 1)


## Setup methods options on the combo box
func _set_method_combo_box(autoload: String) -> void:
	if autoload == "(No one)": # Reset options
		_method_combo_box.set_options([])
		_method_combo_box.editable = false
		return
	
	var methods = []
	var script = load(ProjectSettings.get_setting("autoload/" + autoload).replace("*", "")).new()
	for data in script.get_method_list():
		if not data.name.begins_with("_"):
			methods.append(data.name)
			_methods_params[data.name] = {
				"args": data.args,
				"default_args": data.default_args
			}
	_method_combo_box.set_options(methods)
	_method_combo_box.editable = true


## Set the parameters from a given method in the array
func _set_parameters_array(method: String) -> void:
	if _methods_params[method].args.is_empty():
		return # If method do not have parameters, do nothing
	var params_data = []
	_parameters_field.disable_field(false)
	for param in _methods_params[method].args:
		var param_data = {
			"name": param.name,
			"type": param.type,
			"value": null,
			"metadata": {
				"hint": param.hint,
				"hint_string": param.hint_string,
			}
		}
		params_data.append(param_data)
	_parameters_field.set_array(params_data)


## Handle when an autoload is selected
func _on_autoload_selected(index: int) -> void:
	var autoload = _autoloads_dropdown.get_item_text(index)
	var temp_autoload = _previous_autoload_index
	_previous_autoload_index = index

	var temp_method = _method_combo_box.get_value()
	var temp_params = _parameters_field.get_array()

	_set_method_combo_box(autoload)
	_method_combo_box.set_value("")
	_parameters_field.clear_array()
	_parameters_field.disable_field(true)

	# --- UndoRedo ----------------------------------------------------------
	undo_redo.create_action("Select Autoload")
	undo_redo.add_do_property(_autoloads_dropdown, "selected", index)
	undo_redo.add_undo_property(_autoloads_dropdown, "selected", temp_autoload)

	undo_redo.add_do_method(self , "_set_method_combo_box", autoload)
	undo_redo.add_undo_method(self , "_set_method_combo_box",
			_autoloads_dropdown.get_item_text(temp_autoload))
	undo_redo.add_do_method(_method_combo_box, "set_value", "")
	undo_redo.add_undo_method(_method_combo_box, "set_value", temp_method)

	undo_redo.add_do_method(_parameters_field, "clear_array")
	undo_redo.add_undo_method(_parameters_field, "set_array", temp_params)
	undo_redo.add_do_method(_parameters_field, "disable_field", true)
	undo_redo.add_undo_method(_parameters_field, "disable_field", false)

	undo_redo.add_do_method(self , "emit_signal", "modified", true)
	undo_redo.add_undo_method(self , "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# -----------------------------------------------------------------------


## Handle when an method is selected
func _on_method_selected(method: String) -> void:
	if not _methods_params.has(method):
		return # Is not in the autoload methods
	
	var temp_method = _previous_method
	_previous_method = method
	var temp_params = _parameters_field.get_array()
	_set_parameters_array(method)

	# --- UndoRedo ----------------------------------------------------------
	undo_redo.create_action("Select Method")
	undo_redo.add_do_method(_method_combo_box, "set_value", method)
	undo_redo.add_undo_method(_method_combo_box, "set_value", temp_method)

	undo_redo.add_do_method(_parameters_field, "set_array", _parameters_field.get_array())
	undo_redo.add_undo_method(_parameters_field, "set_array", temp_params)

	undo_redo.add_do_method(self , "emit_signal", "modified", true)
	undo_redo.add_undo_method(self , "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# -----------------------------------------------------------------------


## Handle when parameters change
func _on_parameter_changed(item: Dictionary) -> void:
	var temp_params = _previous_params
	_previous_params = _parameters_field.get_array()

	# --- UndoRedo ----------------------------------------------------------
	undo_redo.create_action("Parameter Changed")
	undo_redo.add_do_method(_parameters_field, "set_array", _previous_params)
	undo_redo.add_undo_method(_parameters_field, "set_array", temp_params)
	undo_redo.add_do_method(self , "emit_signal", "modified", true)
	undo_redo.add_undo_method(self , "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# -----------------------------------------------------------------------

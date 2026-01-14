@tool
extends SproutyDialogsBaseNode

# -----------------------------------------------------------------------------
# Sprouty Dialogs Set Variable Node
# -----------------------------------------------------------------------------
## Node to set a variable value.
# -----------------------------------------------------------------------------

## Emitted when press the expand button in the text box field
signal open_text_editor(text_box: TextEdit)
## Emitted when the text box field gains focus and should update the text editor
signal update_text_editor(text_box: TextEdit)

## Variable name dropdown selector
@onready var _name_input: EditorSproutyDialogsComboBox = $Container/VarField/NameInput
## Operator dropdown selector
@onready var _operator_dropdown: OptionButton = $Container/OperatorDropdown

## Type dropdown selector
var _type_dropdown: OptionButton
## Value input field
var _value_input: Control
## Current value in the input field
var _var_value: Variant = ""
## Current variable name
var _var_name: String = ""

## Selected type (for UndoRedo)
var _type_index: int = TYPE_STRING - 1
## Selected operator (for UndoRedo)
var _operator_index: int = 0

## Flag to indicate if the name has been modified (for UndoRedo)
var _name_modified: bool = false
## Flag to indicate if the value has been modified (for UndoRedo)
var _value_modified: bool = false


func _ready():
	super ()
	_operator_dropdown.item_selected.connect(_on_operator_selected)
	_name_input.input_changed.connect(_on_name_input_changed)
	_name_input.focus_exited.connect(_on_name_input_focus_exited)

	# Set the type dropdown and connect its signal
	$Container/VarField/TypeField.add_child(
		SproutyDialogsVariableUtils.get_types_dropdown(true,
				["Nil", "Variable", "Dictionary", "Array"] # Excluded from options
			))
	_type_dropdown = $Container/VarField/TypeField/TypeDropdown
	_type_dropdown.item_selected.connect(_on_type_selected)

	_type_dropdown.select(_type_index) # Default type (String)
	_set_variable_type(_type_index) # Default type (String)


#region === Node Data ==========================================================

func get_data() -> Dictionary:
	var dict := {}
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"var_name": _name_input.get_value(),
		"var_type": _type_dropdown.get_item_id(_type_dropdown.selected),
		"var_metadata": _type_dropdown.get_item_metadata(_type_dropdown.selected),
		"operator": _operator_dropdown.get_item_id(_operator_dropdown.selected),
		"new_value": _var_value,
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

	# Set the type on the dropdown
	var type_index = _type_dropdown.get_item_index(dict["var_type"])

	if dict["var_metadata"].has("hint"): # Handle File/Dir Path types
		if dict["var_metadata"]["hint"] == PROPERTY_HINT_EXPRESSION:
			type_index = _type_dropdown.item_count - 3
		elif dict["var_metadata"]["hint"] == PROPERTY_HINT_FILE:
			type_index = _type_dropdown.item_count - 2
		elif dict["var_metadata"]["hint"] == PROPERTY_HINT_DIR:
			type_index = _type_dropdown.item_count - 1
	
	_type_dropdown.select(type_index)
	_set_variable_type(type_index)
	
	# Set the variable name, operator and value
	_name_input.set_value(dict["var_name"])
	_operator_dropdown.select(_operator_dropdown.get_item_index(dict["operator"]))
	_set_field_value(dict["new_value"], dict["var_type"])
	_operator_index = _operator_dropdown.selected
	_var_value = dict["new_value"]
	_var_name = dict["var_name"]

#endregion


## Handle when the type is selected from the dropdown
func _set_variable_type(index: int) -> void:
	var type = _type_dropdown.get_item_id(index)
	var metadata = _type_dropdown.get_item_metadata(index)
	if metadata.has("hint"):
		if metadata["hint"] == PROPERTY_HINT_FILE or \
				metadata["hint"] == PROPERTY_HINT_DIR or \
					metadata["hint"] == PROPERTY_HINT_EXPRESSION:
			type = TYPE_STRING # File/Dir Path is treated as String type

	# Set the variable dropdown based on the selected type and update the value field
	_name_input.set_options(SproutyDialogsVariableUtils.get_variables_of_type(type, metadata))
	_set_value_field(type, index)

	# Set the operator dropdown based on the variable type
	var operators = SproutyDialogsVariableUtils.get_assignment_operators(type)
	_operator_dropdown.clear()
	for operator in operators.keys():
		_operator_dropdown.add_item(operator, operators[operator])
	
	# Update the selected indexes and current value for UndoRedo
	_operator_index = _operator_dropdown.selected
	_type_index = index


## Set the value field based on the variable type
func _set_value_field(type: int, index: int) -> void:
	# Clear previous field
	if $Container/ValueField.get_child_count() > 0:
		var field = $Container/ValueField.get_child(0)
		$Container/ValueField.remove_child(field)
		field.queue_free()
	
	# Create new field based on type
	var field_data = SproutyDialogsVariableUtils.new_field_by_type(
			type, null, _type_dropdown.get_item_metadata(index),
			_on_value_changed, _on_value_input_modified
		)
	field_data.field.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	$Container/ValueField.add_child(field_data.field)
	_var_value = field_data.default_value
	_value_input = field_data.field

	 # Connect the expand button to open the text editor
	if type == TYPE_STRING and field_data.field is HBoxContainer:
		var text_box = field_data.field.get_node("TextEdit")
		field_data.field.get_node("ExpandButton").pressed.connect(
				open_text_editor.emit.bind(text_box))
		text_box.focus_entered.connect(update_text_editor.emit.bind(text_box))
	
	if type == TYPE_BOOL: # Adjust size horizontally
		size.x += field_data.field.get_size().x
	
	_on_resized()


## Set the input field value
func _set_field_value(value: Variant, type: int) -> void:
	_var_value = value
	SproutyDialogsVariableUtils.set_field_value(_value_input, type, value)


## Handle when the type is selected from the dropdown
func _on_type_selected(index: int) -> void:
	var temp_type = _type_index
	var temp_operator = _operator_index
	var temp_value = _var_value
	_set_variable_type(index)
	modified.emit(true)

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Set Variable Type")
	undo_redo.add_do_method(self, "_set_variable_type", index)
	undo_redo.add_do_property(_type_dropdown, "selected", index)

	undo_redo.add_undo_method(self, "_set_variable_type", temp_type)
	undo_redo.add_undo_property(_type_dropdown, "selected", temp_type)
	undo_redo.add_undo_property(_operator_dropdown, "selected", temp_operator)
	undo_redo.add_undo_method(self, "_set_field_value", temp_value, temp_type)

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------


## Handle when the variable name in the input field changes
func _on_name_input_changed(new_text: String) -> void:
	if new_text != _var_name:
		var temp_name = _var_name
		_var_name = new_text
		_name_modified = true

		# --- UndoRedo -----------------------------------------------------
		undo_redo.create_action("Set Variable Name", 1)
		undo_redo.add_do_method(_name_input, "set_value", new_text)
		undo_redo.add_undo_method(_name_input, "set_value", temp_name)
		undo_redo.add_do_method(self, "emit_signal", "modified", true)
		undo_redo.add_undo_method(self, "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# ------------------------------------------------------------------


## Handle when the variable name input field loses focus
func _on_name_input_focus_exited() -> void:
	if _name_modified:
		_name_modified = false
		modified.emit(true)


## Handle when the operator is selected from the dropdown
func _on_operator_selected(index: int) -> void:
	if index != _operator_index:
		var temp = _operator_index
		_operator_index = index
		modified.emit(true)

		# --- UndoRedo -----------------------------------------------------
		undo_redo.create_action("Set Variable Operator")
		undo_redo.add_do_property(_operator_dropdown, "selected", index)
		undo_redo.add_undo_property(_operator_dropdown, "selected", temp)
		undo_redo.add_do_method(self, "emit_signal", "modified", true)
		undo_redo.add_undo_method(self, "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# ------------------------------------------------------------------


## Handle when the value in the input field changes
func _on_value_changed(value: Variant, type: int, field: Control) -> void:
	if typeof(value) == typeof(_var_value) and value == _var_value:
		return # No value change
	
	var temp_value = _var_value
	_var_value = value
	_value_modified = true

	# --- UndoRedo -------------------------------------------------------------
	undo_redo.create_action("Set Variable Value", 1)
	undo_redo.add_do_method(self, "_set_field_value", value, type)
	undo_redo.add_undo_method(self, "_set_field_value", temp_value, type)
	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# --------------------------------------------------------------------------


## Handle when the value input was modified (focus lost)
func _on_value_input_modified() -> void:
	if _value_modified:
		_value_modified = false
		modified.emit(true)
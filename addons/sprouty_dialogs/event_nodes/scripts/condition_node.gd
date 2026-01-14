@tool
extends SproutyDialogsBaseNode

# -----------------------------------------------------------------------------
# Sprouty Dialogs Condition Node 
# -----------------------------------------------------------------------------
## Node to add branches conditions to the dialog tree.
# -----------------------------------------------------------------------------

## Emitted when press the expand button in the text box field
signal open_text_editor(text_box: TextEdit)
## Emitted when the text box field gains focus and should update the text editor
signal update_text_editor(text_box: TextEdit)

## Operator dropdown selector
@onready var operator_dropdown: OptionButton = $Container/OperatorDropdown

## Both variable type dropdown selectors
var _type_dropdowns: Array = [null, null]
## Both variable value input fields
var _value_inputs: Array = [null, null]
## Variable values for the condition
var _var_values: Array = ["", ""]

## Selected type (for UndoRedo)
var _type_indexes: Array[int] = [40, 40]
## Selected operator (for UndoRedo)
var _operator_index: int = 0

## Flag to indicate if the value has been modified (for UndoRedo)
var _values_modified: Array[bool] = [false, false]


func _ready():
	super ()
	_set_type_dropdown($Container/FirstVar/TypeField, 0)
	_set_type_dropdown($Container/SecondVar/TypeField, 1)
	
	# Set the operators in the operator dropdown
	operator_dropdown.item_selected.connect(_on_operator_selected)
	var operators = SproutyDialogsVariableUtils.get_comparison_operators()
	operator_dropdown.clear()
	for operator in operators.keys():
		operator_dropdown.add_item(operator, operators[operator])


## Set the type dropdowns and connect their signals
func _set_type_dropdown(dropdown_field: Node, field_index: int) -> void:
	var types_dropdown = SproutyDialogsVariableUtils.get_types_dropdown(
			true, ["Nil", "Dictionary", "Array"] # Excluded from options
		)
	dropdown_field.add_child(types_dropdown)
	_type_dropdowns[field_index] = dropdown_field.get_node("TypeDropdown")
	_type_dropdowns[field_index].item_selected.connect(_on_type_selected.bind(field_index))

	_type_dropdowns[field_index].select(0) # Default type (Variable)
	_set_value_field(0, field_index) # Default type (Variable)


#region === Node Data ==========================================================

func get_data() -> Dictionary:
	var dict := {}
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"first_var": {
			"type": _type_dropdowns[0].get_item_id(_type_dropdowns[0].selected),
			"metadata": _type_dropdowns[0].get_item_metadata(_type_dropdowns[0].selected),
			"value": _var_values[0]
		},
		"second_var": {
			"type": _type_dropdowns[1].get_item_id(_type_dropdowns[1].selected),
			"metadata": _type_dropdowns[1].get_item_metadata(_type_dropdowns[1].selected),
			"value": _var_values[1]
		},
		"operator": operator_dropdown.get_item_id(operator_dropdown.selected),
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

	# Set the types on the dropdowns
	load_type_data(dict, 0)
	load_type_data(dict, 1)

	# Set the operator and values
	operator_dropdown.select(operator_dropdown.get_item_index(dict["operator"]))
	_set_field_value(dict["first_var"]["value"], dict["first_var"]["type"], 0)
	_set_field_value(dict["second_var"]["value"], dict["second_var"]["type"], 1)
	_var_values = [dict["first_var"]["value"], dict["second_var"]["value"]]
	_operator_index = operator_dropdown.selected


## Load type data into the dropdown and value field
func load_type_data(data: Dictionary, field_index: int) -> void:
	var key = "first_var" if field_index == 0 else "second_var"
	var type_index = _type_dropdowns[field_index].get_item_index(data[key]["type"])

	if data[key]["metadata"].has("hint"): # Handle File/Dir Path types
		if data[key]["metadata"]["hint"] == PROPERTY_HINT_EXPRESSION:
			type_index = _type_dropdowns[field_index].item_count - 3
		elif data[key]["metadata"]["hint"] == PROPERTY_HINT_FILE:
			type_index = _type_dropdowns[field_index].item_count - 2
		elif data[key]["metadata"]["hint"] == PROPERTY_HINT_DIR:
			type_index = _type_dropdowns[field_index].item_count - 1
	
	_type_dropdowns[field_index].select(type_index)
	_set_value_field(type_index, field_index)
	_type_indexes[field_index] = type_index

#endregion


## Set a value field based on the variable type
func _set_value_field(type_index: int, field_index: int) -> void:
	var type = _type_dropdowns[field_index].get_item_id(type_index)
	var value_field = $Container/FirstVar/ValueField if field_index == 0 \
			else $Container/SecondVar/ValueField
	
	# Handle File/Dir Path types
	var metadata = _type_dropdowns[field_index].get_item_metadata(type_index)
	if metadata.has("hint"):
		if metadata["hint"] == PROPERTY_HINT_FILE or \
				metadata["hint"] == PROPERTY_HINT_DIR or \
					metadata["hint"] == PROPERTY_HINT_EXPRESSION:
			type = TYPE_STRING # File/Dir Path is treated as String type
	
	# Remove the previous value field if it exists
	if value_field.get_child_count() > 0:
		var field = value_field.get_child(0)
		value_field.remove_child(field)
		field.queue_free()
	
	# Set the value field based on the variable type
	var field_data = SproutyDialogsVariableUtils.new_field_by_type(
			type, null, _type_dropdowns[field_index].get_item_metadata(type_index),
			_on_value_changed.bind(field_index), _on_value_input_modified.bind(field_index)
		)
	field_data.field.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	value_field.add_child(field_data.field)
	_value_inputs[field_index] = field_data.field
	_var_values[field_index] = field_data.default_value
	_type_indexes[field_index] = type_index

	# Connect the expand button to open the text editor
	if type == TYPE_STRING and field_data.field is HBoxContainer:
		var text_box = field_data.field.get_node("TextEdit")
		field_data.field.get_node("ExpandButton").pressed.connect(
				open_text_editor.emit.bind(text_box))
		text_box.focus_entered.connect(update_text_editor.emit.bind(text_box))
	
	_on_resized()


## Set the input field value
func _set_field_value(value: Variant, type: int, field_index: int) -> void:
	_var_values[field_index] = value
	SproutyDialogsVariableUtils.set_field_value(
			_value_inputs[field_index], type, value)


## Handle when a type is selected from the dropdown
func _on_type_selected(type_index: int, field_index: int) -> void:
	var temp_type = _type_indexes[field_index]
	var temp_value = _var_values[field_index]
	_set_value_field(type_index, field_index)
	modified.emit(true)

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Set Condition Type")
	undo_redo.add_do_method(self, "_set_value_field", type_index, field_index)
	undo_redo.add_do_property(_type_dropdowns[field_index], "selected", type_index)

	undo_redo.add_undo_method(self, "_set_value_field", temp_type, field_index)
	undo_redo.add_undo_property(_type_dropdowns[field_index], "selected", temp_type)
	undo_redo.add_undo_method(self, "_set_field_value", temp_value, temp_type, field_index)

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	#-----------------------------------------------------------------------


## Handle when the operator is selected from the dropdown
func _on_operator_selected(index: int) -> void:
	if index != _operator_index:
		var temp = _operator_index
		_operator_index = index
		modified.emit(true)

		# --- UndoRedo -----------------------------------------------------
		undo_redo.create_action("Set Condition Operator")
		undo_redo.add_do_property(operator_dropdown, "selected", index)
		undo_redo.add_undo_property(operator_dropdown, "selected", temp)
		undo_redo.add_do_method(self, "emit_signal", "modified", true)
		undo_redo.add_undo_method(self, "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# ------------------------------------------------------------------


## Handle when the value changes in any of the value fields
func _on_value_changed(value: Variant, type: int, field: Control, field_index: int) -> void:
	if typeof(value) == typeof(_var_values[field_index]) and value == _var_values[field_index]:
		return # No value change
	
	var temp_value = _var_values[field_index]
	_var_values[field_index] = value
	_values_modified[field_index] = true

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Set Condition Value", 1)
	undo_redo.add_do_method(self, "_set_field_value", value, type, field_index)
	undo_redo.add_undo_method(self, "_set_field_value", temp_value, type, field_index)
	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ------------------------------------------------------------------


## Handle when a value input field loses focus
func _on_value_input_modified(field_index: int) -> void:
	if _values_modified[field_index]:
		_values_modified[field_index] = false
		modified.emit(true)
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
var _type_dropdowns: Array = []
## Variable values for the condition
var _var_values: Array = ["", ""]


func _ready():
	super ()
	_set_type_dropdown($Container/FirstVar/TypeField, 0)
	_set_type_dropdown($Container/SecondVar/TypeField, 1)
	
	# Set the operators in the operator dropdown
	operator_dropdown.item_selected.connect(_on_operator_changed)
	var operators = EditorSproutyDialogsVariableManager.get_comparison_operators()
	operator_dropdown.clear()
	for operator in operators.keys():
		operator_dropdown.add_item(operator, operators[operator])


## Set the type dropdowns and connect their signals
func _set_type_dropdown(dropdown_field: Node, field_index: int) -> void:
	var types_dropdown = EditorSproutyDialogsVariableManager.get_types_dropdown(true, true)
	dropdown_field.add_child(types_dropdown)
	_type_dropdowns.insert(field_index, dropdown_field.get_node("TypeDropdown"))
	_type_dropdowns[field_index].item_selected.connect(_on_type_selected.bind(field_index))
	_type_dropdowns[field_index].select(0) # Default type (Variable)
	_on_type_selected(0, field_index) # Default type (Variable)


#region === Overridden Methods =================================================

func get_data() -> Dictionary:
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"first_type": _type_dropdowns[0].get_item_id(_type_dropdowns[0].selected),
		"first_value": _var_values[0],
		"operator": operator_dropdown.get_item_id(operator_dropdown.selected),
		"second_type": _type_dropdowns[1].get_item_id(_type_dropdowns[1].selected),
		"second_value": _var_values[1],
		"to_node": ["END", "END"], # Default to END in case no connections
		"offset": position_offset,
		"size": size
	}
	for connection in connections:
		dict[name.to_snake_case()]["to_node"].set(
			connection["from_port"], connection["to_node"].to_snake_case())
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	to_node = dict["to_node"]
	position_offset = dict["offset"]
	size = dict["size"]

	# Set the types on the dropdowns
	var first_type_index = _type_dropdowns[0].get_item_index(dict["first_type"])
	_type_dropdowns[0].select(first_type_index)
	_on_type_selected(first_type_index, 0)
	var second_type_index = _type_dropdowns[1].get_item_index(dict["second_type"])
	_type_dropdowns[1].select(second_type_index)
	_on_type_selected(second_type_index, 1)

	# Set the operator and values
	operator_dropdown.select(operator_dropdown.get_item_index(dict["operator"]))
	EditorSproutyDialogsVariableManager.set_field_value(
		$Container/FirstVar/ValueField.get_child(0), dict["first_type"], dict["first_value"])
	EditorSproutyDialogsVariableManager.set_field_value(
		$Container/SecondVar/ValueField.get_child(0), dict["second_type"], dict["second_value"])
	_var_values = [dict["first_value"], dict["second_value"]]

#endregion


## Handle when a type is selected from the dropdown
func _on_type_selected(type_index: int, field_index: int) -> void:
	var type = _type_dropdowns[field_index].get_item_id(type_index)
	_set_value_field(type, field_index)
	modified.emit(true)
	_on_resized()


## Set a value field based on the variable type
func _set_value_field(type: int, field_index: int) -> void:
	var value_field = $Container/FirstVar/ValueField if field_index == 0 \
			else $Container/SecondVar/ValueField
	
	# Remove the previous value field if it exists
	if value_field.get_child_count() > 0:
		var field = value_field.get_child(0)
		value_field.remove_child(field)
		field.queue_free()
	
	# Set the value field based on the variable type
	var field_data = EditorSproutyDialogsVariableManager.get_field_by_type(
			type, _on_value_changed.bind(field_index))
	field_data.field.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	value_field.add_child(field_data.field)
	_var_values[field_index] = field_data.default_value

	if type == TYPE_STRING: # Connect the expand button to open the text editor
		var text_box = field_data.field.get_node("TextEdit")
		field_data.field.get_node("ExpandButton").pressed.connect(
				open_text_editor.emit.bind(text_box))
		text_box.focus_entered.connect(update_text_editor.emit.bind(text_box))


## Handle when the value changes in any of the value fields
func _on_value_changed(value: Variant, field_index: int) -> void:
	if _var_values[field_index] != value:
		_var_values[field_index] = value
		modified.emit(true)


## Handle when the operator is changed in the operator dropdown
func _on_operator_changed(operator_index: int) -> void:
	if operator_dropdown.selected != operator_index:
		modified.emit(true)
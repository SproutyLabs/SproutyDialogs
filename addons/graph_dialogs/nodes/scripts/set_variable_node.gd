@tool
class_name SetVariableNode
extends BaseNode

# -----------------------------------------------------------------------------
## Set Variable Node
##
## Node to set a variable value.
# -----------------------------------------------------------------------------

## Emitted when press the expand button in the string value field
signal open_text_editor(text_edit: TextEdit)

## Variable name dropdown selector
@onready var _name_input: GraphDialogsComboBox = $Container/VarField/NameInput
## Operator dropdown selector
@onready var _operator_dropdown: OptionButton = $Container/OperatorDropdown

## Type dropdown selector
var _type_dropdown: OptionButton
## Value input field
var _value_input: Control

## New variable value to set
var _new_var_value: Variant = ""


func _ready():
	super ()
	_name_input.text_changed.connect(graph_editor.on_modified)
	$Container/VarField/TypeField.add_child(GraphDialogsVariableManager.get_types_dropdown())
	_type_dropdown = $Container/VarField/TypeField/TypeDropdown
	_type_dropdown.item_selected.connect(_on_type_selected)
	_type_dropdown.select(3) # Default type (String)
	_on_type_selected(3) # Default type (String)


#region === Overridden Methods =================================================

func get_data() -> Dictionary:
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"var_name": _name_input.get_value(),
		"var_type": _type_dropdown.get_item_id(_type_dropdown.selected),
		"operator": _operator_dropdown.get_item_id(_operator_dropdown.selected),
		"new_value": _new_var_value,
		"to_node": [connections[0]["to_node"].to_snake_case()]
				if connections.size() > 0 else ["END"],
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
	_type_dropdown.select(type_index)
	_on_type_selected(type_index)
	
	# Set the variable name, operator and value
	_name_input.set_value(dict["var_name"])
	_operator_dropdown.select(_operator_dropdown.get_item_index(dict["operator"]))
	GraphDialogsVariableManager.set_field_value(
		$Container/ValueField.get_child(0), dict["var_type"], dict["new_value"])
	_new_var_value = dict["new_value"]

#endregion


## Handle when the type is selected from the dropdown
func _on_type_selected(index: int) -> void:
	var type = _type_dropdown.get_item_id(index)
	# Set the variable dropdown based on the selected type and update the value field
	_name_input.set_options(GraphDialogsVariableManager.get_variable_list(type))
	_set_value_field(type)
	# Set the operator dropdown based on the variable type
	var operators = GraphDialogsVariableManager.get_assignment_operators(type)
	_operator_dropdown.clear()
	for operator in operators.keys():
		_operator_dropdown.add_item(operator, operators[operator])
	graph_editor.on_modified()
	_on_resized()


## Set the value field based on the variable type
func _set_value_field(type: int) -> void:
	if $Container/ValueField.get_child_count() > 0:
		var field = $Container/ValueField.get_child(0)
		$Container/ValueField.remove_child(field)
		field.queue_free()
	var field_data = GraphDialogsVariableManager.get_field_by_type(type, _on_value_changed)
	field_data.field.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	$Container/ValueField.add_child(field_data.field)
	_new_var_value = field_data.default_value

	if type == TYPE_STRING: # Connect the expand button to open the text editor
		var text_box = field_data.field.get_node("TextEdit")
		field_data.field.get_node("ExpandButton").pressed.connect(
			graph_editor.open_text_editor.emit.bind(text_box))
		text_box.focus_entered.connect(
			graph_editor.update_text_editor.emit.bind(text_box))
	
	if type == TYPE_BOOL: # Adjust size horizontally
		size.x += field_data.field.get_size().x


## Handle when the value in the input field changes
func _on_value_changed(value: Variant) -> void:
	_new_var_value = value
	graph_editor.on_modified()
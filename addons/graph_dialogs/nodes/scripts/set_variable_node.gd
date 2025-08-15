@tool
class_name SetVariableNode
extends BaseNode

## -----------------------------------------------------------------------------
## Set Variable Node
##
## Node to set a variable value.
## -----------------------------------------------------------------------------

## Variable name dropdown selector
@onready var _name_input: GraphDialogsComboBox = $Container/NameInput
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
	$Container/TypeField.add_child(GraphDialogsVariableManager.get_types_dropdown())
	_type_dropdown = $Container/TypeField/TypeDropdown
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
		"operator": _operator_dropdown.selected,
		"new_value": _new_var_value,
		"to_node": [connections[0]["to_node"].to_snake_case()]
				if connections.size() > 0 else ["END"],
		"offset": position_offset
	}
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	to_node = dict["to_node"]
	position_offset = dict["offset"]

	_type_dropdown.select(dict["var_type"])
	#value_input.change_var_type(dict["var_type"])

	# TODO: filter variables by type

	_name_input.set_value(dict["var_name"])
	_operator_dropdown.select(dict["operator"])
	GraphDialogsVariableManager.set_field_value(
		$Container/ValueField.get_child(0), dict["var_type"], dict["new_value"])
	_new_var_value = dict["new_value"]

#endregion


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

	#if type == TYPE_STRING: # Connect the expand button to open the text editor
	#	field_data.field.get_node("ExpandButton").pressed.connect(
	#		open_text_editor.emit.bind(field_data.field.get_node("TextEdit")))


## Handle when the type is selected from the dropdown
func _on_type_selected(index: int) -> void:
	var type = _type_dropdown.get_item_id(index)
	var variables = GraphDialogsVariableManager.get_variables_by_type(type)
	_name_input.set_options(variables.keys())
	_set_value_field(type)
	size.y = 0 # Resize node


## Handle when the value in the input field changes
func _on_value_changed(value: Variant) -> void:
	_new_var_value = value
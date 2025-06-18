@tool
class_name SetVariableNode
extends BaseNode

## -----------------------------------------------------------------------------
## Set Variable Node
##
## Node to set a variable value.
## -----------------------------------------------------------------------------

## Variable type dropdown selector
@onready var type_selector: OptionButton = $Container/Type
## Variable name dropdown selector
@onready var var_selector: OptionButton = $Container/Variable
## Operator dropdown selector
@onready var operator_selector: OptionButton = $Container/Operator
## Value input field
@onready var value_input: VariableInputField = $Container/ValueInput


func _ready():
	super ()

#region === Overridden Methods =================================================

func get_data() -> Dictionary:
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"var_name": var_selector.get_item_text(var_selector.selected),
		"var_type": type_selector.selected,
		"operator": operator_selector.selected,
		"var_value": value_input.get_value(),
		"to_node": [connections[0]["to_node"].to_snake_case()]
				if connections.size() > 0 else ["END"],
		"offset": position_offset
	}
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	type_selector.select(dict["var_type"])
	value_input.change_var_type(dict["var_type"])
	# TODO: filter variables by type
	for item_index in var_selector.item_count:
		if var_selector.get_item_text(item_index) == dict["var_name"]:
			var_selector.select(item_index)
			break
	operator_selector.select(dict["operator"])
	value_input.set_value(dict["var_value"])
	
	to_node = dict["to_node"]
	position_offset = dict["offset"]

#endregion

func _on_type_item_selected(index: int) -> void:
	value_input.change_var_type(index)

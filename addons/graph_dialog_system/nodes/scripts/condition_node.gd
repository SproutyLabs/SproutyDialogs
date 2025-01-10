@tool
extends BaseNode

@onready var type_selector : OptionButton = $Container/Type
@onready var var_selector : OptionButton = $Container/Variable
@onready var operator_selector : OptionButton = $Container/Operator
@onready var value_input : VariableInputField = $Container/ValueInput

func _ready():
	super()

func get_data() -> Dictionary:
	# Get node data on dict
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type_id" : node_type_id,
		"var_name" : var_selector.get_item_text(var_selector.selected),
		"var_type" : type_selector.selected,
		"operator" : operator_selector.selected,
		"var_value" : value_input.get_value(),
		"to_node" : [] if connections.size() > 0 else ["END"],
		"offset" : {
			"x" : position_offset.x,
			"y" : position_offset.y
		}
	}
	if dict["to_node"][0] != "END":
		for connection in connections:
			dict[name.to_snake_case()]["to_node"].append(
				connection["to_node"].to_snake_case()
			)
	
	return dict

func set_data(dict: Dictionary) -> void:
	# Set node data from dict
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
	position_offset.x = dict["offset"]["x"]
	position_offset.y = dict["offset"]["y"]

func _on_type_item_selected(index : int) -> void:
	value_input.change_var_type(index)

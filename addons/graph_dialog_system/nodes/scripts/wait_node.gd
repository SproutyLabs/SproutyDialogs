@tool
extends BaseNode

@onready var time_input : SpinBox = $Container/SpinBox
@onready var time_value : float = time_input.value

func _ready():
	super()

func get_data() -> Dictionary:
	# Get node data on dict
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type_id" : node_type_id,
		"node_index" : node_index,
		"time" : time_value,
		"to_node" : [connections[0]["to_node"].to_snake_case()]
				if connections.size() > 0 else ["END"],
		"offset" : {
			"x" : position_offset.x,
			"y" : position_offset.y
		}
	}
	return dict

func set_data(dict: Dictionary) -> void:
	# Set node data from dict
	node_index = dict["node_index"]
	time_value = dict["time"]
	time_input.value = dict["time"]
	
	to_node = dict["to_node"]
	position_offset.x = dict["offset"]["x"]
	position_offset.y = dict["offset"]["y"]

func _on_time_value_changed(value : float) -> void:
	time_value = value
	get_parent().on_modified()

@tool
extends BaseNode

const NODE_TYPE_ID : int = 7

@onready var time : float = SpinBox.value

func _ready():
	super()

func get_data() -> Dictionary:
	# Get node data on dict
	var dict := {}
	var connections: Array = get_parent().get_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type_id" : NODE_TYPE_ID,
		"time" : time,
		"to_node" : connections[0]["to_node"] if connections.size() > 0 else ["END"],
		"offset" : {
			"x" : position_offset.x,
			"y" : position_offset.y
		}
	}
	return dict

func set_data(dict: Dictionary) -> void:
	# Set node data from dict
	time = dict["time"]
	to_node = [dict["to_node"]]
	position_offset.x = dict["offset"]["x"]
	position_offset.y = dict["offset"]["y"]

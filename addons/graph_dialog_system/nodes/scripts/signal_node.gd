@tool
extends BaseNode

const NODE_TYPE_ID : int = 6

@onready var name_input : LineEdit = $NameInput
@onready var signal_name : String = name_input.text

func _ready():
	super()

func get_data() -> Dictionary:
	# Get node data on dict
	var dict := {}
	var connections: Array = get_parent().get_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type_id" : NODE_TYPE_ID,
		"signal_name" : LineEdit.text,
		"to_node" : connections[0]["to_node"] if connections.size() > 0 else ["END"],
		"offset" : {
			"x" : position_offset.x,
			"y" : position_offset.y
		}
	}
	return dict

func set_data(dict: Dictionary) -> void:
	# Set node data from dict
	signal_name = dict["signal_name"]
	LineEdit.text = dict["signal_name"]
	to_node = [dict["to_node"]]
	position_offset.x = dict["offset"]["x"]
	position_offset.y = dict["offset"]["y"]

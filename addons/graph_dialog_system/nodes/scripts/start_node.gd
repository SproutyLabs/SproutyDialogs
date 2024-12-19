@tool
extends BaseNode

@onready var ID_input : LineEdit = %IDInput
@onready var start_id : String = ID_input.text
@onready var play_button : TextureButton = %PlayButton

func _ready():
	super()

func _get_data(graph: GraphEdit) -> Dictionary:
	# Get node data on dict
	var dict := {}
	var connections: Array = graph.get_connections(name)
	
	dict[name.to_snake_case()] = {
		"start_id" : start_id,
		"to_node" : connections[0]["to_node"] if connections.size() > 0 else "END",
		"offset" : {
			"x" : position_offset.x,
			"y" : position_offset.y
		}
	}
	return dict

func _set_data(dict: Dictionary) -> Array[String]:
	# Set node data from dict and return connections
	start_id = dict["start_id"]
	ID_input.text = start_id
	position_offset.x = dict["offset"]["x"]
	position_offset.y = dict["offset"]["y"]
	return [dict["to_node"]]

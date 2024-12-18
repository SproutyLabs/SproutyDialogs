@tool
extends BaseNode

@onready var ID_input : LineEdit = %IDInput
@onready var start_id : String = ID_input.text
@onready var play_button : TextureButton = %PlayButton

func _ready():
	super()

func _to_dict(graph: GraphEdit) -> Dictionary:
	# Get node data to dict
	var dict := {}
	var connections: Array = graph.get_connections(name)
	
	dict["node_type"] = "start_node"
	dict["start_id"] = ID_input.text
	dict["connections"] = {
		"to_node": connections[0]["to_node"] if connections.size() > 0 else "END"
	}
	return dict

func _from_dict(dict: Dictionary) -> void:
	# Set node data from dict
	start_id = dict["start_id"]
	ID_input.text = start_id

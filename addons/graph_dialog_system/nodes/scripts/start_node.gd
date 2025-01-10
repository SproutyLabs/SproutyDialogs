@tool
extends BaseNode

const NODE_TYPE_ID : int = 0

@onready var ID_input : LineEdit = %IDInput
@onready var play_button : TextureButton = %PlayButton

func _ready():
	super()

func get_data() -> Dictionary:
	# Get node data on dict
	var dict := {}
	var connections: Array = get_parent().get_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type_id" : NODE_TYPE_ID,
		"start_id" : ID_input.text,
		"to_node" : connections[0]["to_node"] if connections.size() > 0 else ["END"],
		"offset" : {
			"x" : position_offset.x,
			"y" : position_offset.y
		}
	}
	return dict

func set_data(dict: Dictionary) -> void:
	# Set node data from dict
	ID_input.text = dict["start_id"]
	node_dialog_id = dict["start_id"]
	to_node = [dict["to_node"]]
	position_offset.x = dict["offset"]["x"]
	position_offset.y = dict["offset"]["y"]

func _on_id_input_text_changed(new_text):
	node_dialog_id = new_text

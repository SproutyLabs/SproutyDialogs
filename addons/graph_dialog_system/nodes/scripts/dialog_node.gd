@tool
extends BaseNode

const NODE_TYPE_ID : int = 2

@onready var char_selector : OptionButton = %CharacterSelect
@onready var char_key : String = char_selector.get_item_text(char_selector.selected)
@onready var dialog_key : String = ""

func _ready():
	super()

func get_data() -> Dictionary:
	# Get node data on dict
	var dict := {}
	var connections: Array = get_parent().get_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type_id" : NODE_TYPE_ID,
		"char_key" : "",
		"dialog_key" : "",
		"to_node" : connections[0]["to_node"] if connections.size() > 0 else ["END"],
		"offset" : {
			"x" : position_offset.x,
			"y" : position_offset.y
		}
	}
	return dict

func set_data(dict: Dictionary) -> void:
	# Set node data from dict
	char_key = dict["char_key"]
	dialog_key = dict["dialog_key"]
	to_node = [dict["to_node"]]
	position_offset.x = dict["offset"]["x"]
	position_offset.y = dict["offset"]["y"]

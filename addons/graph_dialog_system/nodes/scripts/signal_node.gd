@tool
extends BaseNode

## -----------------------------------------------------------------------------
## Signal Node
##
## Node to emit a signal between dialog nodes.
## -----------------------------------------------------------------------------

## Signal name text input
@onready var name_input: LineEdit = $NameInput
## Signal name value
@onready var signal_name: String = name_input.text


func _ready():
	super()


func get_data() -> Dictionary:
	# Get node data on dict
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"signal_name": signal_name,
		"to_node": [connections[0]["to_node"].to_snake_case()]
				if connections.size() > 0 else ["END"],
		"offset": {
			"x": position_offset.x,
			"y": position_offset.y
		}
	}
	return dict


func set_data(dict: Dictionary) -> void:
	# Set node data from dict
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	signal_name = dict["signal_name"]
	name_input.text = dict["signal_name"]
	
	to_node = dict["to_node"]
	position_offset.x = dict["offset"]["x"]
	position_offset.y = dict["offset"]["y"]


func _on_input_text_changed(new_text: String) -> void:
	signal_name = new_text
	get_parent().on_modified()

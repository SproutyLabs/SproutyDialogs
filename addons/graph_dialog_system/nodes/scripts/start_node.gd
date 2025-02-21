@tool
extends BaseNode

@onready var ID_input : LineEdit = %IDInput
@onready var start_id : String = ID_input.text
@onready var play_button : TextureButton = %PlayButton

func _ready():
	super()
	start_node = self # Assign as start dialog node

func get_data() -> Dictionary:
	# Get node data on dict
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type_id" : node_type_id,
		"node_index" : node_index,
		"start_id" : start_id,
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
	node_type_id = dict["node_type_id"]
	node_index = dict["node_index"]
	start_id = dict["start_id"]
	ID_input.text = dict["start_id"]
	
	to_node = dict["to_node"]
	position_offset.x = dict["offset"]["x"]
	position_offset.y = dict["offset"]["y"]

func get_start_id() -> String:
	# Return the dialog ID
	return start_id

func _on_id_input_changed(new_text : String) -> void:
	# Become the id text to uppercase and save it
	var caret_pos = ID_input.caret_column
	ID_input.text = new_text.to_upper()
	ID_input.caret_column = caret_pos
	start_id = new_text
	get_parent().on_modified()

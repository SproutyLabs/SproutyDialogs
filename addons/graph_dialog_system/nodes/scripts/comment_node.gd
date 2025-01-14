@tool
extends BaseNode

@onready var text_input : TextEdit = $TextInput
@onready var comment_text : String = text_input.text

func _ready():
	super()

func get_data() -> Dictionary:
	# Get node data on dict
	var dict := {}
	
	dict[name.to_snake_case()] = {
		"node_type_id" : node_type_id,
		"comment_text" : comment_text,
		"offset" : {
			"x" : position_offset.x,
			"y" : position_offset.y
		}
	}
	return dict

func set_data(dict: Dictionary) -> void:
	# Set node data from dict and return connections
	comment_text = dict["comment_text"]
	text_input.text = dict["comment_text"]
	position_offset.x = dict["offset"]["x"]
	position_offset.y = dict["offset"]["y"]

func _on_input_text_changed() -> void:
	comment_text = text_input.text
	get_parent().on_modified()

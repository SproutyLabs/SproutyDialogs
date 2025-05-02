@tool
extends BaseNode

## -----------------------------------------------------------------------------
## Comment Node
##
## Node to add comments to the graph.
## -----------------------------------------------------------------------------

## Text input box reference
@onready var text_input: TextEdit = $TextInput
## Comment text
@onready var comment_text: String = text_input.text


func _ready():
	super ()


func get_data() -> Dictionary:
	var dict := {}
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"comment_text": comment_text,
		"offset": {
			"x": position_offset.x,
			"y": position_offset.y
		}
	}
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	comment_text = dict["comment_text"]
	text_input.text = dict["comment_text"]
	position_offset.x = dict["offset"]["x"]
	position_offset.y = dict["offset"]["y"]


func _on_input_text_changed() -> void:
	comment_text = text_input.text
	get_parent().on_modified()

@tool
class_name StartNode
extends BaseNode

## -----------------------------------------------------------------------------
## Start Node
##
## Node to start a dialog tree and assign an ID to it.
## -----------------------------------------------------------------------------

## ID input text field
@onready var id_input_text: LineEdit = %IDInput
## Start ID value
@onready var start_id: String = id_input_text.text
## Play button to run the dialog
@onready var play_button: TextureButton = %PlayButton

## Empty field error style for input text
var input_error_style := preload("res://addons/graph_dialogs/theme/input_text_error.tres")
## Flag to check if the error alert is displaying
var displaying_error: bool = false
## Error alert to show when the ID input is empty
var id_error_alert: GraphDialogsAlert


func _ready():
	super ()
	start_node = self # Assign as start dialog node

#region === Overridden Methods =================================================

func get_data() -> Dictionary:
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"start_id": start_id,
		"to_node": [connections[0]["to_node"].to_snake_case()]
				if connections.size() > 0 else ["END"],
		"offset": position_offset
	}
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	start_id = dict["start_id"]
	id_input_text.text = dict["start_id"]
	
	to_node = dict["to_node"]
	position_offset = dict["offset"]

#endregion

## Return the dialog ID
func get_start_id() -> String:
	return start_id


## Update the dialog ID and become it to uppercase
func _on_id_input_changed(new_text: String) -> void:
	if displaying_error:
		# Remove error style and hide alert when input is changed
		id_input_text.remove_theme_stylebox_override("normal")
		graph_editor.alerts.hide_alert(id_error_alert)
		id_error_alert = null
		displaying_error = false
	# Keep the caret position when uppercase the text
	var caret_pos = id_input_text.caret_column
	id_input_text.text = new_text.to_upper()
	id_input_text.caret_column = caret_pos
	start_id = new_text
	get_parent().on_modified()


## Show an error alert when the ID input is empty
func _on_id_input_focus_exited() -> void:
	if id_input_text.text.is_empty():
		id_input_text.add_theme_stylebox_override("normal", input_error_style)
		if id_error_alert == null:
			id_error_alert = graph_editor.alerts.show_alert(
				"Start node #" + str(node_index) + " needs an ID", "ERROR")
		else: graph_editor.alerts.focus_alert(id_error_alert)
		displaying_error = true


func _on_node_deselected() -> void:
	# Active error alert when ID input is empty on node deselected
	_on_id_input_focus_exited()


func _on_tree_exiting() -> void:
	# Hide active error alert on node destroy
	graph_editor.alerts.hide_alert(id_error_alert)

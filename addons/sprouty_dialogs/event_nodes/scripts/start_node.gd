@tool
extends SproutyDialogsBaseNode

# -----------------------------------------------------------------------------
# Sprouty Dialogs Start Node
# -----------------------------------------------------------------------------
## Node to start a dialog tree and assign an ID to it.
# -----------------------------------------------------------------------------

## Emitted when press the play button to run the dialog from this node
signal play_dialog_request(start_id: String)

## ID input text field
@onready var _id_input_text: LineEdit = %IDInput
## Start ID value
@onready var _start_id: String = _id_input_text.text
## Play button to run the dialog
@onready var _play_button: Button = %PlayButton

## Empty field error style for input text
var _input_error_style := preload("res://addons/sprouty_dialogs/editor/theme/input_text_error.tres")
## Flag to check if the error alert is displaying
var _displaying_error: bool = false
## Error alert to show when the ID input is empty
var _id_error_alert: EditorSproutyDialogsAlert

## Flag to check if the ID was modified
var _id_modified: bool = false


func _ready():
	super ()
	# Connect signals
	_id_input_text.text_changed.connect(_on_id_input_changed)
	_id_input_text.focus_exited.connect(_on_id_input_focus_exited)
	_play_button.pressed.connect(_on_play_button_pressed)
	node_deselected.connect(_on_node_deselected)
	tree_exiting.connect(_on_tree_exiting)
	start_node = self # Assign as start dialog node


#region === Node Data ==========================================================

func get_data() -> Dictionary:
	var dict := {}
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"start_id": _start_id.to_upper(),
		"to_node": get_output_connections(),
		"offset": position_offset,
		"size": size
	}
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	to_node = dict["to_node"]
	position_offset = dict["offset"]
	size = dict["size"]

	_start_id = dict["start_id"]
	_id_input_text.text = dict["start_id"]

#endregion


## Return the dialog ID
func get_start_id() -> String:
	return _start_id.to_upper()


## Update the dialog ID and become it to uppercase
func _on_id_input_changed(new_text: String) -> void:
	if _displaying_error:
		# Remove error style and hide alert when input is changed
		_id_input_text.remove_theme_stylebox_override("normal")
		get_parent().alerts.hide_alert(_id_error_alert)
		_id_error_alert = null
		_displaying_error = false
	
	# Keep the caret position when uppercase the text
	var caret_pos = _id_input_text.caret_column
	_id_input_text.text = new_text.to_upper()
	_id_input_text.caret_column = caret_pos

	if _start_id != new_text:
		var temp = _start_id
		_start_id = new_text
		_id_modified = true

		# --- UndoRedo --------------------------------------------------
		undo_redo.create_action("Edit Start ID", 1)
		undo_redo.add_do_property(self, "_start_id", new_text)
		undo_redo.add_do_property(_id_input_text, "text", new_text.to_upper())
		undo_redo.add_undo_property(self, "_start_id", temp)
		undo_redo.add_undo_property(_id_input_text, "text", temp.to_upper())
		undo_redo.add_undo_method(self, "_on_id_input_focus_exited")

		undo_redo.add_do_method(self, "emit_signal", "modified", true)
		undo_redo.add_undo_method(self, "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# ---------------------------------------------------------------


## Show error alerts when the ID input loses focus
func _on_id_input_focus_exited() -> void:
	if _id_modified:
		_id_modified = false
		modified.emit(true)
	
	# Show error if the ID input is empty
	if _id_input_text.text.is_empty():
		_id_input_text.add_theme_stylebox_override("normal", _input_error_style)
		if _id_error_alert == null:
			_id_error_alert = get_parent().alerts.show_alert(
				"Start Node #" + str(node_index) + " needs an ID", 0)
		else: get_parent().alerts.focus_alert(_id_error_alert)
		_displaying_error = true
	else:
		# Show error if the ID already exists in another node
		var nodes: Array = get_parent().get_children()
		for node in nodes:
			if node is SproutyDialogsBaseNode and node.node_type == "start_node" \
					and node != self and node.get_start_id() == _id_input_text.text:
				_id_input_text.add_theme_stylebox_override("normal", _input_error_style)
				if _id_error_alert == null:
					_id_error_alert = get_parent().alerts.show_alert(
						"Start Node #" + str(node.node_index) + " already has the ID '" \
						+ _id_input_text.text + "'", 0)
				else: get_parent().alerts.focus_alert(_id_error_alert)
				_displaying_error = true
				break


## Active error alert when ID input is empty on node deselected
func _on_node_deselected() -> void:
	_on_id_input_focus_exited()


## Hide active error alert on node destroy
func _on_tree_exiting() -> void:
	get_parent().alerts.hide_alert(_id_error_alert)


## Play the dialog from the current graph starting from the given ID
func _on_play_button_pressed() -> void:
	play_dialog_request.emit(get_start_id())
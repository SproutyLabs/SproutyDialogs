@tool
extends SproutyDialogsBaseNode

# -----------------------------------------------------------------------------
# Sprouty Dialogs Signal Node
# -----------------------------------------------------------------------------
## Node to emit a signal between dialog nodes.
# -----------------------------------------------------------------------------

## Emitted when press the expand button in a text box field
signal open_text_editor(text_box: TextEdit)
## Emitted when a text box field gains focus and should update the text editor
signal update_text_editor(text_box: TextEdit)

## Extra arguments array
@onready var _args_array: EditorSproutyDialogsArrayField = $ArgsArray
## Signal argument text input
@onready var _identifier_input: LineEdit = $IdentifierInput
## Signal name argument value
@onready var _signal_identifier: String = _identifier_input.text

## Flag to check if the identifier was modified
var _identifier_modified: bool = false

## Previous args array (for UndoRedo)
var _previous_args: Array = []


func _ready():
	super ()
	# Connect signals
	_identifier_input.text_changed.connect(_on_identifier_input_changed)
	_identifier_input.focus_exited.connect(_on_identifier_input_focus_exited)
	_args_array.item_changed.connect(_on_args_array_changed.unbind(1))
	_args_array.array_changed.connect(_on_args_array_changed.unbind(1))
	_args_array.open_text_editor.connect(open_text_editor.emit)
	_args_array.update_text_editor.connect(update_text_editor.emit)
	_args_array.modified.connect(modified.emit.bind(true))
	_args_array.resized.connect(_on_resized)


#region === Node Data ==========================================================

func get_data() -> Dictionary:
	var dict := {}
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"signal_id": _signal_identifier,
		"extra_args": _args_array.get_array(),
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

	if dict.has("signal_argument"):
		_signal_identifier = dict["signal_argument"]
		_identifier_input.text = dict["signal_argument"]
	else:
		_signal_identifier = dict["signal_id"]
		_identifier_input.text = dict["signal_id"]

	if dict.has("extra_args"):
		_args_array.set_array(dict["extra_args"])
		_previous_args = dict["extra_args"]

#endregion


## Handle when the signal identifier input is changed
func _on_identifier_input_changed(new_text: String) -> void:
	if _signal_identifier != new_text:
		var temp = _signal_identifier
		_signal_identifier = new_text
		_identifier_modified = true

		# --- UndoRedo --------------------------------------------------
		undo_redo.create_action("Edit Signal", 1)
		undo_redo.add_do_property(self , "_signal_identifier", _signal_identifier)
		undo_redo.add_do_property(_identifier_input, "text", _signal_identifier)
		undo_redo.add_undo_property(self , "_signal_identifier", temp)
		undo_redo.add_undo_property(_identifier_input, "text", temp)

		undo_redo.add_do_method(self , "emit_signal", "modified", true)
		undo_redo.add_undo_method(self , "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# ---------------------------------------------------------------


## Trigger the modified signal when the text input focus is exited
func _on_identifier_input_focus_exited() -> void:
	if _identifier_modified:
		_identifier_modified = false
		modified.emit(true)


## Handle when the extra arguments array change
func _on_args_array_changed() -> void:
	var temp_args = _previous_args
	_previous_args = _args_array.get_array()

	# --- UndoRedo ----------------------------------------------------------
	undo_redo.create_action("Arguments Changed")
	undo_redo.add_do_method(_args_array, "set_array", _previous_args)
	undo_redo.add_undo_method(_args_array, "set_array", temp_args)
	undo_redo.add_do_method(self , "emit_signal", "modified", true)
	undo_redo.add_undo_method(self , "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# -----------------------------------------------------------------------
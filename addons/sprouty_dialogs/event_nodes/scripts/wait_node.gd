@tool
extends SproutyDialogsBaseNode

# -----------------------------------------------------------------------------
# Sprouty Dialogs Wait Node
# -----------------------------------------------------------------------------
## Node to add a wait time to the dialog.
# -----------------------------------------------------------------------------

## Time input spin box
@onready var _time_input: SpinBox = $Container/TimeInput
## Close dialog box check
@onready var _close_dialog_check: CheckButton = $CloseDialogToggle
## Wait time value
@onready var _wait_time: float = _time_input.value

## Flag to check if the time was modified
var _time_modified: bool = false


func _ready():
	super ()
	_time_input.value_changed.connect(_on_time_value_changed)
	_time_input.focus_exited.connect(_on_time_input_focus_exited)
	_close_dialog_check.toggled.connect(_on_close_dialog_toggled)


#region === Node Data ==========================================================

func get_data() -> Dictionary:
	var dict := {}
	
	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"wait_time": _wait_time,
		"close_dialog": _close_dialog_check.button_pressed,
		"to_node": get_output_connections(),
		"to_dialog": to_dialog,
		"offset": position_offset,
		"size": size
	}
	return dict


func set_data(dict: Dictionary) -> void:
	node_type = dict["node_type"]
	node_index = dict["node_index"]
	to_node = dict["to_node"]
	to_dialog = dict.get("to_dialog", "")
	position_offset = dict["offset"]
	size = dict["size"]

	_wait_time = dict["wait_time"]
	_time_input.value = dict["wait_time"]
	_close_dialog_check.set_pressed_no_signal(dict.get("close_dialog", false))

#endregion


func _on_time_value_changed(value: float) -> void:
	if _wait_time != value:
		var temp = _wait_time
		_wait_time = value
		_time_modified = true

		# --- UndoRedo --------------------------------------------------
		undo_redo.create_action("Edit Wait Time", 1)
		undo_redo.add_do_property(self, "_wait_time", _wait_time)
		undo_redo.add_do_property(_time_input, "value", _wait_time)
		undo_redo.add_undo_property(self, "_wait_time", temp)
		undo_redo.add_undo_property(_time_input, "value", temp)

		undo_redo.add_do_method(self, "emit_signal", "modified", true)
		undo_redo.add_undo_method(self, "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# ---------------------------------------------------------------


func _on_time_input_focus_exited() -> void:
	if _time_modified:
		_time_modified = false
		modified.emit(true)


func _on_close_dialog_toggled(toggled_on: bool) -> void:
	# --- UndoRedo --------------------------------------------------
	undo_redo.create_action("Toggle Close Dialog")
	undo_redo.add_do_method(_close_dialog_check, "set_pressed_no_signal", toggled_on)
	undo_redo.add_undo_method(_close_dialog_check, "set_pressed_no_signal", not toggled_on)
	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ---------------------------------------------------------------
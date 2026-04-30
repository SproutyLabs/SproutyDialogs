@tool
extends SproutyDialogsBaseNode

# -----------------------------------------------------------------------------
# Sprouty Dialogs Jump To Node
# -----------------------------------------------------------------------------
## Node to jump to another dialogue branch and return to the next output.
# -----------------------------------------------------------------------------

## Emitted when is requesting to open a dialogue file
signal open_file_request(path: String)

## Start ID input field.
@onready var _target_input: EditorSproutyDialogsComboBox = %TargetIdInput
## Start ID value.
@onready var _target_id: String = _target_input.text
## Jump to another dialogue file toggle
@onready var _jump_to_dialogue_toggle: CheckButton = $JumpToDialogueToggle
## Dialogue section container
@onready var _dialogue_container: VBoxContainer = $DialogueContainer
## Dialogue file button
@onready var _dialogue_button: Button = %DialogueButton

## Dialogue data resource
var _dialogue_data: SproutyDialogsDialogueData
## Dialogue resource picker
var _dialogue_picker: EditorSproutyDialogsResourcePicker

## Empty field error style for input text.
var _input_error_style := preload("res://addons/sprouty_dialogs/editor/theme/input_text_error.tres")
## Flag to check if the error alert is displaying.
var _displaying_error: bool = false
## Error alert to show when the target input is invalid.
var _target_error_alert: EditorSproutyDialogsAlert

## Flag to check if the ID was modified.
var _id_modified: bool = false


func _ready():
	super ()
	_target_input.input_changed.connect(_on_target_input_changed)
	_target_input.input_focus_exited.connect(_on_target_input_focus_exited)
	node_deselected.connect(_on_node_deselected)
	tree_exiting.connect(_on_tree_exiting)
	_refresh_target_options()

	if get_parent() and get_parent().has_signal("modified"):
		get_parent().modified.connect(_on_graph_modified)
	
	_jump_to_dialogue_toggle.toggled.connect(_on_jump_to_dialogue_toggled)
	_set_dialogue_picker()

	_dialogue_container.hide()
	_on_resized()


#region === Node Data ==========================================================

func get_data() -> Dictionary:
	var dict := {}

	dict[name.to_snake_case()] = {
		"node_type": node_type,
		"node_index": node_index,
		"to_id": _target_id.to_upper(),
		"jump_to_dialogue": _jump_to_dialogue_toggle.button_pressed,
		"to_dialogue_uid": ResourceSaver.get_resource_id_for_path(
				_dialogue_data.resource_path, true) if _dialogue_data else -1,
		"to_dialogue_path": _dialogue_data.resource_path if _dialogue_data else "",
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

	_target_id = dict.get("to_id", "")
	_target_input.set_value(_target_id)

	if dict.has("to_dialogue_uid"):
		if SproutyDialogsFileUtils.check_valid_uid_path(dict["to_dialogue_uid"]):
			var path = ResourceUID.get_id_path(dict["to_dialogue_uid"])
			_load_dialogue(load(path))
		elif not dict["to_dialogue_path"].is_empty():
			printerr("[Sprouty Dialogs] The dialogue file '" + dict["to_dialogue_path"]
				+ "' cannot be found by Jump To Node #" + str(node_index)
				+ ". Please check if the dialogue file exist or select another one.")
	
	_jump_to_dialogue_toggle.button_pressed = dict.get("jump_to_dialogue", false)

#endregion


## Refresh the available target IDs from the graph editor.
func _refresh_target_options() -> void:
	if _jump_to_dialogue_toggle.button_pressed:
		if _dialogue_data:
			_target_input.set_options(_dialogue_data.get_start_ids())
		else:
			_target_input.set_options([])
	else:
		if get_parent() and get_parent().has_method("get_start_ids"):
			_target_input.set_options(get_parent().get_start_ids())


## Validate the target ID against the graph editor start IDs.
func _is_valid_target_id(target_id: String) -> bool:
	if target_id.is_empty():
		return false
	
	var from = get_parent()
	if _jump_to_dialogue_toggle.button_pressed:
		from = _dialogue_data # Get the start ids from selected dialogue file
	
	if not from or not from.has_method("get_start_ids"):
		return false
	for start_id in from.get_start_ids():
		if str(start_id).to_upper() == target_id.to_upper():
			return true
	return false


## Handle when the graph is modified.
func _on_graph_modified(_modified: bool) -> void:
	_refresh_target_options()


## Update the target ID and become it uppercase.
func _on_target_input_changed(new_text: String) -> void:
	if _displaying_error:
		_hide_alerts()

	var target_text = new_text.to_upper()
	var caret_pos = _target_input.caret_column
	_target_input.text = target_text
	_target_input.caret_column = caret_pos

	if _target_id != target_text:
		var temp = _target_id
		_target_id = target_text
		_id_modified = true

		# --- UndoRedo --------------------------------------------------
		undo_redo.create_action("Edit Jump Target", 1)
		undo_redo.add_do_property(self, "_target_id", target_text)
		undo_redo.add_do_property(_target_input, "text", target_text)
		undo_redo.add_undo_property(self, "_target_id", temp)
		undo_redo.add_undo_property(_target_input, "text", temp)
		undo_redo.add_undo_method(self, "_on_target_input_focus_exited")

		undo_redo.add_do_method(self, "emit_signal", "modified", true)
		undo_redo.add_undo_method(self, "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# ---------------------------------------------------------------


## Show error alerts when the target input loses focus.
func _on_target_input_focus_exited() -> void:
	if _id_modified:
		_id_modified = false
		modified.emit(true)

	if _target_input.text.is_empty() or not _is_valid_target_id(_target_input.text):
		_target_input.add_theme_stylebox_override("normal", _input_error_style)
		if _target_error_alert == null:
			var message = "Jump To Node #" + str(node_index) + " needs a valid Start ID"
			if not _target_input.text.is_empty():
				message = "Jump To Node #" + str(node_index) + " cannot find the Start ID '" \
					+ _target_input.text + "'"
			_target_error_alert = get_parent().alerts.show_alert(message, 0)
		else:
			get_parent().alerts.focus_alert(_target_error_alert)
		_displaying_error = true
	else:
		_hide_alerts()


# Hide the displayed alerts
func _hide_alerts() -> void:
	_target_input.remove_theme_stylebox_override("normal")
	if _target_error_alert:
		get_parent().alerts.hide_alert(_target_error_alert)
	_target_error_alert = null
	_displaying_error = false


## Active error alert when input is empty on node deselected.
func _on_node_deselected() -> void:
	_on_target_input_focus_exited()


## Hide active error alert on node destroy.
func _on_tree_exiting() -> void:
	if get_parent() and _target_error_alert:
		get_parent().alerts.hide_alert(_target_error_alert)


#region === Handle Dialogue Selection ==========================================

## Load the dialogue data from the file field
func _load_dialogue(dialogue: Resource) -> void:
	if not dialogue:
		_clear_dialogue_field()
		return
	
	var path = dialogue.resource_path
	if not dialogue is SproutyDialogsDialogueData:
		printerr("[Sprouty Dialogs] Invalid dialogue resource: " + path)
		_clear_dialogue_field()
		return
	
	# Show the character's display name and set the portrait dropdown
	_dialogue_button.disabled = false
	_dialogue_button.text = path.get_file().get_basename().capitalize()
	if _dialogue_button.pressed.is_connected(open_file_request.emit.bind(path)):
		_dialogue_button.pressed.disconnect(open_file_request.emit.bind(path))
	_dialogue_button.pressed.connect(open_file_request.emit.bind(path))
	_refresh_target_options()
	_dialogue_data = dialogue


## Set the dialogue resource picker
func _set_dialogue_picker() -> void:
	_dialogue_picker = EditorSproutyDialogsResourcePicker.new()
	_dialogue_picker.resource_type = _dialogue_picker.ResourceType.DIALOGUE
	_dialogue_picker.add_clear_button = true
	_dialogue_button.get_parent().add_child(_dialogue_picker)
	_dialogue_picker.resource_picked.connect(_on_dialogue_changed)
	_dialogue_picker.clear_pressed.connect(_on_dialogue_clear)
	_dialogue_button.disabled = true


## Handle when the jump to dialogue button is toggled
func _on_jump_to_dialogue_toggled(toggled_on: bool) -> void:
	_dialogue_container.visible = toggled_on
	_on_target_input_focus_exited()
	_refresh_target_options()
	_on_resized()
	modified.emit(true)
	
	# --- UndoRedo ----------------------------------------------------------
	undo_redo.create_action("Toggle Jump To Dialogue")
	undo_redo.add_do_method(_jump_to_dialogue_toggle, "set_pressed_no_signal", toggled_on)
	undo_redo.add_undo_method(_jump_to_dialogue_toggle, "set_pressed_no_signal", not toggled_on)
	
	undo_redo.add_do_property(_dialogue_container, "visible", toggled_on)
	undo_redo.add_undo_property(_dialogue_container, "visible", not toggled_on)
	undo_redo.add_do_method(self, "_refresh_target_options")
	undo_redo.add_undo_method(self, "_refresh_target_options")
	undo_redo.add_do_method(self, "_on_resized")
	undo_redo.add_undo_method(self, "_on_resized")

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# -----------------------------------------------------------------------


## Handle the dialogue file path changed signal
func _on_dialogue_changed(res: Resource) -> void:
	if not res:
		return
	var prev_dialogue = _dialogue_data
	var prev_target_id = _target_id
	_target_input.text = ""
	_target_id = ""
	_load_dialogue(res)
	modified.emit(true)
	
	# --- UndoRedo ----------------------------------------------------------
	undo_redo.create_action("Assign Dialogue")
	undo_redo.add_do_method(self, "_load_dialogue", res)
	undo_redo.add_undo_method(self, "_load_dialogue", prev_dialogue)

	undo_redo.add_do_property(self, "_target_id", "")
	undo_redo.add_do_property(_target_input, "text", "")
	undo_redo.add_undo_property(self, "_target_id", prev_target_id)
	undo_redo.add_undo_property(_target_input, "text", prev_target_id)

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# -----------------------------------------------------------------------


# Handle when the dialogue is cleared
func _on_dialogue_clear() -> void:
	var prev_dialogue = _dialogue_data
	var prev_target_id = _target_id
	_target_input.text = ""
	_target_id = ""
	_clear_dialogue_field()
	modified.emit(true)

	# --- UndoRedo ----------------------------------------------------------
	undo_redo.create_action("Clear Dialogue")
	undo_redo.add_do_method(self, "_clear_dialogue_field")
	undo_redo.add_undo_method(self, "_load_dialogue", prev_dialogue)

	undo_redo.add_do_property(self, "_target_id", "")
	undo_redo.add_do_property(_target_input, "text", "")
	undo_redo.add_undo_property(self, "_target_id", prev_target_id)
	undo_redo.add_undo_property(_target_input, "text", prev_target_id)

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# -----------------------------------------------------------------------


## Clear the character field and reset the portrait dropdown
func _clear_dialogue_field() -> void:
	_dialogue_data = null
	_refresh_target_options()
	_dialogue_button.text = "(No one)"
	_dialogue_button.disabled = true

#endregion
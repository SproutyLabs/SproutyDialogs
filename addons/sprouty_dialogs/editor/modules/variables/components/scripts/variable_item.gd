@tool
class_name EditorSproutyDialogsVariableItem
extends Container

# -----------------------------------------------------------------------------
# Sprouty Dialogs Variable Item Component
# -----------------------------------------------------------------------------
## Component that represents a single variable item in the variable editor panel.
## It allows the user to set the variable name, type and value.
# -----------------------------------------------------------------------------

## Emitted when the variable is modified
signal modified(modified: bool)

## Emitted when the variable is changed
signal variable_changed(var_data: Dictionary)
## Emitted when the variable is renamed
signal variable_renamed(old_name: String, new_name: String)
## Emitted when the remove button is pressed
signal remove_pressed()

## Emitted when a expand button is pressed to open the text editor
signal open_text_editor(text_box: LineEdit)
## Emitted when change the focus to another text box to update the text editor
signal update_text_editor(text_box: LineEdit)

## Variable name input field
@onready var _name_input: LineEdit = $Container/NameInput
## Value field parent for the variable value
@onready var _value_field: Control = $Container/ValueField
## Drop highlight line
@onready var _drop_highlight: ColorRect = $DropHighlight
## Modified indicator to show if the variable has been modified
@onready var _modified_indicator: Label = $Container/ModifiedIndicator

## Type dropdown selector
var _type_dropdown: OptionButton

## The variable name
var _variable_name: String = "New Variable"
## The variable type
var _variable_type: int = TYPE_STRING
## The variable type index in the dropdown
var _variable_type_index: int = TYPE_STRING - 1
## The variable value
var _variable_value: Variant = ""

## Parent group of the item
var parent_group: Node = null

## Flag to indicate that the item has just been created
var new_item: bool = true

## Modified counter to track changes
var _modified_counter: int = 0

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready() -> void:
	_set_types_dropdown()
	_set_value_field(_type_dropdown.get_item_index(_variable_type))
	_name_input.editing_toggled.connect(_on_name_changed)
	$Container/RemoveButton.icon = get_theme_icon("Remove", "EditorIcons")
	$Container/RemoveButton.pressed.connect(_on_remove_button_pressed)

	# Drag and drop setup
	$Container/DragButton.set_drag_forwarding(_get_drag_data, _can_drop_data, _drop_data)
	$Container/DragButton.mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_exited.connect(hide_drop_highlight)
	mouse_filter = Control.MOUSE_FILTER_PASS

	_drop_highlight.color = get_theme_color("accent_color", "Editor")
	hide_drop_highlight()
	_name_input.text = _variable_name
	_modified_indicator.hide()
	_on_name_changed(false) # Initialize the name input field


## Returns the variable data as a dictionary
func get_variable_data() -> Dictionary:
	return {
		"name": _variable_name,
		"type": _variable_type,
		"value": _variable_value,
		"metadata": _type_dropdown.get_item_metadata(_type_dropdown.selected)
	}


## Return the item path in the variables tree
func get_item_path() -> String:
	if parent_group is EditorSproutyDialogsVariableGroup:
		return parent_group.get_item_path() + "/" + _variable_name
	else:
		return _variable_name


## Returns the variable name
func get_item_name() -> String:
	return _variable_name


## Returns the variable type
func get_type() -> int:
	return _variable_type


## Returns the variable value
func get_value() -> Variant:
	return _variable_value


## Rename the variable item
func set_item_name(new_name: String) -> void:
	_variable_name = new_name
	_name_input.text = new_name
	update_path_tooltip()


## Set the variable type
func set_type(type: int, metadata: Dictionary) -> void:
	_variable_type = type
	var index = _type_dropdown.get_item_index(type)
	if metadata.has("hint"): # Handle File/Dir Path types
		if metadata["hint"] == PROPERTY_HINT_EXPRESSION:
			index = _type_dropdown.item_count - 3
		elif metadata["hint"] == PROPERTY_HINT_FILE:
			index = _type_dropdown.item_count - 2
		elif metadata["hint"] == PROPERTY_HINT_DIR:
			index = _type_dropdown.item_count - 1
	
	_type_dropdown.select(index)
	_set_value_field(index)


## Set the variable value
## The value type must match the current variable type
func set_value(value: Variant) -> void:
	_variable_value = value
	if _value_field.get_child_count() > 0:
		var field = _value_field.get_child(0)
		SproutyDialogsVariableUtils.set_field_value(field, _variable_type, value)


## Update the tooltip with the current item path
func update_path_tooltip() -> void:
	var path = get_item_path()
	_name_input.tooltip_text = path
	$Container/Icon.tooltip_text = path


## Mark the variable item as modified
func mark_as_modified(was_modified: bool) -> void:
	if was_modified:
		if _modified_counter == 0:
			_modified_indicator.show()
			modified.emit(true)
		_modified_counter += 1
	else:
		_modified_counter -= 1
		if _modified_counter <= 0:
			_modified_indicator.hide()
			_modified_counter = 0
			modified.emit(false)


## Clear the modified state of the variable item
func clear_modified_state() -> void:
	_modified_counter = 0
	_modified_indicator.hide()


## Set the types dropdown
func _set_types_dropdown() -> void:
	if $Container/TypeField.get_child_count() > 0:
		$Container/TypeField/TypeDropdown.queue_free()
	_type_dropdown = SproutyDialogsVariableUtils.get_types_dropdown(true, [
		"Nil", "Variable", "Dictionary", "Array" # Excluded from options
	])
	_type_dropdown.select(_type_dropdown.get_item_index(TYPE_STRING))
	_type_dropdown.item_selected.connect(_on_type_changed)
	_type_dropdown.fit_to_longest_item = true
	_type_dropdown.flat = true
	$Container/TypeField.add_child(_type_dropdown)


## Set the value field based on the variable type
func _set_value_field(type_index: int) -> void:
	# Clear previous field
	if _value_field.get_child_count() > 0:
		var field = _value_field.get_child(0)
		_value_field.remove_child(field)
		field.queue_free()

	# Get the type
	var type = _type_dropdown.get_item_id(type_index)
	var metadata = _type_dropdown.get_item_metadata(type_index)
	if metadata.has("hint"):
		if metadata["hint"] == PROPERTY_HINT_FILE or \
				metadata["hint"] == PROPERTY_HINT_DIR or \
					metadata["hint"] == PROPERTY_HINT_EXPRESSION:
			type = TYPE_STRING # File/Dir Path is treated as String type
	
	# Create the new value field
	var field_data = SproutyDialogsVariableUtils.new_field_by_type(
			type, null, metadata, _on_value_changed, mark_as_modified.bind(true))
	field_data.field.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	_value_field.add_child(field_data.field)
	_variable_value = field_data.default_value
	_variable_type_index = type_index
	_variable_type = type

	# Connect the expand button to open the text editor
	if type == TYPE_STRING and field_data.field is HBoxContainer:
		var text_box = field_data.field.get_node("TextEdit")
		field_data.field.get_node("ExpandButton").pressed.connect(
			open_text_editor.emit.bind(text_box))
		text_box.focus_entered.connect(update_text_editor.emit.bind(text_box))


## Set the value in the value field
func _set_field_value(value: Variant, type: int) -> void:
	SproutyDialogsVariableUtils.set_field_value(_value_field.get_child(0), type, value)


## Handle the name change event
func _on_name_changed(toggled_on: bool) -> void:
	if toggled_on: return # Ignore when editing starts
	var new_name = _name_input.text.strip_edges()
	var old_name = _variable_name
	_variable_name = new_name
	variable_renamed.emit(old_name, new_name)
	variable_changed.emit(get_variable_data())


## Handle the type change event
func _on_type_changed(type_index: int) -> void:
	var temp_type = _variable_type
	var temp_value = _variable_value
	var temp_index = _variable_type_index
	_set_value_field(type_index)
	variable_changed.emit(get_variable_data())
	mark_as_modified(true)

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Change '" + _variable_name + "' Variable Type")
	undo_redo.add_do_method(_type_dropdown, "select", type_index)
	undo_redo.add_do_method(self, "_set_value_field", type_index)

	undo_redo.add_undo_method(_type_dropdown, "select", temp_index)
	undo_redo.add_undo_method(self, "_set_value_field", temp_index)
	undo_redo.add_undo_method(self, "_set_field_value", temp_value, temp_type)

	undo_redo.add_do_method(self, "mark_as_modified", true)
	undo_redo.add_undo_method(self, "mark_as_modified", false)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------


## Handle the value change event
func _on_value_changed(value: Variant, type: int, field: Control) -> void:
	var temp = _variable_value
	_variable_value = value
	variable_changed.emit(get_variable_data())

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Change '" + _variable_name + "' Variable Value", 1)
	undo_redo.add_do_method(self, "_set_field_value", value, type)
	undo_redo.add_undo_method(self, "_set_field_value", temp, type)

	undo_redo.add_do_method(self, "mark_as_modified", true)
	undo_redo.add_undo_method(self, "mark_as_modified", false)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------


## Handle the remove button pressed event
func _on_remove_button_pressed() -> void:
	remove_pressed.emit()


#region === Drag and Drop ======================================================

## Show the drop highlight above or below the item
func show_drop_highlight(above: bool = true) -> void:
	if above: # Show the highlight above the item
		_drop_highlight.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	else: # Show the highlight below the item
		_drop_highlight.size_flags_vertical = Control.SIZE_SHRINK_END
	_drop_highlight.show()


## Hide the drop highlight
func hide_drop_highlight() -> void:
	_drop_highlight.hide()


func _get_drag_data(at_position: Vector2) -> Variant:
	var preview = Label.new()
	preview.text = "Dragging: " + _variable_name
	set_drag_preview(preview)
	var data = {
	    "item": self,
	    "group": get_parent(),
		"type": "item"
	}
	return data


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var can = data.has("type") and data.item != self and data.item != get_parent()
	if can: show_drop_highlight(at_position.y < size.y / 2)
	else: _drop_highlight.hide()
	return can


func _drop_data(at_position: Vector2, data: Variant) -> void:
	_drop_highlight.hide()
	var from_group = data.group
	var from_index = from_group.get_children().find(data.item)
	var to_group = get_parent()
	from_group.remove_child(data.item)
	to_group.add_child(data.item)
	var to_index = to_group.get_children().find(self)

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Move Variable "
		+ ("Group" if data.type == "group" else "Item"))
	
	undo_redo.add_do_method(from_group, "remove_child", data.item)
	undo_redo.add_do_method(to_group, "add_child", data.item)
	undo_redo.add_undo_method(to_group, "remove_child", data.item)
	undo_redo.add_undo_method(from_group, "add_child", data.item)
	undo_redo.add_undo_reference(data.item)
	# ----------------------------------------------------------------------

	if at_position.y < size.y / 2:
		# Insert at the top
		to_group.move_child(data.item, to_index)
		# --- UndoRedo ---------------------------------------------------------
		undo_redo.add_do_method(to_group, "move_child", data.item, to_index)
		# ----------------------------------------------------------------------
	else:
		# Insert at the bottom
		to_group.move_child(data.item, to_index + 1)
		# --- UndoRedo ---------------------------------------------------------
		undo_redo.add_do_method(to_group, "move_child", data.item, to_index + 1)
		# ----------------------------------------------------------------------

	data.item.parent_group = parent_group
	data.item.update_path_tooltip()
	data.item.mark_as_modified(true)
	
	# Emit renamed signal to ensure unique names
	data.item.emit_signal(("group" if data.type == "group" else "variable") + "_renamed",
			data.item.get_item_name(), data.item.get_item_name())

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.add_undo_method(from_group, "move_child", data.item, from_index)
	undo_redo.add_undo_property(data.item, "parent_group", from_group)
	undo_redo.add_undo_method(data.item, "update_path_tooltip")

	undo_redo.add_do_property(data.item, "parent_group", to_group)
	undo_redo.add_do_method(data.item, "update_path_tooltip")

	undo_redo.add_do_method(data.item, "mark_as_modified", true)
	undo_redo.add_undo_method(data.item, "mark_as_modified", false)
	undo_redo.commit_action(false)
	# ----------------------------------------------------------------------

#endregion
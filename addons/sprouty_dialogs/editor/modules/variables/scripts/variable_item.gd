@tool
class_name EditorSproutyDialogsVariableItem
extends Container

# -----------------------------------------------------------------------------
# Sprouty Dialogs Variable Item Component
# -----------------------------------------------------------------------------
## This class represents a single variable item in the Sprouty Dialogs editor.
## It allows the user to set the variable name, type and value.
# -----------------------------------------------------------------------------

## Emited when the variable is changed
signal variable_changed(name: String, type: int, value: Variant)
## Emited when the variable is renamed
signal variable_renamed(name: String)
## Emited when the remove button is pressed
signal remove_pressed()
## Emitted when a expand button is pressed to open the text editor
signal open_text_editor(text_box: LineEdit)
## Emitted when change the focus to another text box to update the text editor
signal update_text_editor(text_box: LineEdit)

## The variable name
@export var _variable_name: String = ""
## The variable type
@export var _variable_type: int = TYPE_STRING
## The variable value
@export var _variable_value: Variant = ""

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

## Parent group of the item
var parent_group: Node = null


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

	show_as_modified(false)
	_on_name_changed(false) # Initialize the name input field


## Get the variable data as a dictionary
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
		if metadata["hint"] == PROPERTY_HINT_FILE:
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
		EditorSproutyDialogsVariableManager.set_field_value(field, _variable_type, value)
	show_as_modified(false)


## Show the modified indicator
func show_as_modified(show: bool) -> void:
	_modified_indicator.visible = show


## Update the tooltip with the current item path
func update_path_tooltip() -> void:
	var path = get_item_path()
	_name_input.tooltip_text = path
	$Container/Icon.tooltip_text = path


## Set the types dropdown
func _set_types_dropdown() -> void:
	if $Container/TypeField.get_child_count() > 0:
		$Container/TypeField/TypeDropdown.queue_free()
	_type_dropdown = EditorSproutyDialogsVariableManager.get_types_dropdown(true, [
		"Nil", "Variable", "Dictionary", "Array" # Excluded from options
	])
	_type_dropdown.select(_type_dropdown.get_item_index(TYPE_STRING))
	_type_dropdown.item_selected.connect(_on_type_changed)
	_type_dropdown.fit_to_longest_item = true
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
				metadata["hint"] == PROPERTY_HINT_DIR:
			type = TYPE_STRING # File/Dir Path is treated as String type
	
	# Create the new value field
	var field_data = EditorSproutyDialogsVariableManager.new_field_by_type(
			type, null, metadata, _on_value_changed)
	field_data.field.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	_value_field.add_child(field_data.field)
	_variable_value = field_data.default_value
	_variable_type = type

	# Connect the expand button to open the text editor
	if type == TYPE_STRING and field_data.field is HBoxContainer:
		var text_box = field_data.field.get_node("TextEdit")
		field_data.field.get_node("ExpandButton").pressed.connect(
			open_text_editor.emit.bind(text_box))
		text_box.focus_entered.connect(update_text_editor.emit.bind(text_box))
		

## Handle the name change event
func _on_name_changed(toggled_on: bool) -> void:
	if toggled_on: return # Ignore when editing starts
	var new_name = _name_input.text.strip_edges()
	if new_name == "": new_name = "New Variable"
	_variable_name = new_name
	show_as_modified(true)
	variable_renamed.emit(_variable_name)
	variable_changed.emit(_variable_name, _variable_type, _variable_value)


## Handle the type change event
func _on_type_changed(type_index: int) -> void:
	_set_value_field(type_index) # Update the value field based on the new type
	show_as_modified(true)
	variable_changed.emit(_variable_name, _variable_type, _variable_value)


## Handle the value change event
func _on_value_changed(value: Variant, type: int, field: Control) -> void:
	_variable_value = value
	show_as_modified(true)
	variable_changed.emit(_variable_name, type, value)


## Handle the remove button pressed event
func _on_remove_button_pressed() -> void:
	remove_pressed.emit()
	if get_parent(): # Remove this item from its parent
		get_parent().remove_child(self)
		queue_free()


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
	var to_group = get_parent()
	from_group.remove_child(data.item)
	var index = to_group.get_children().find(self)

	if at_position.y < size.y / 2:
		# Insert at the top
		to_group.add_child(data.item)
		to_group.move_child(data.item, index)
	else:
		# Insert at the bottom
		to_group.add_child(data.item)
		to_group.move_child(data.item, index + 1)
	
	data.item.parent_group = parent_group
	data.item.update_path_tooltip()

#endregion
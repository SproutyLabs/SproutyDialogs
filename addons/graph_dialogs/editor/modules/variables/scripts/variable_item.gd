@tool
class_name GraphDialogsVariableItem
extends Container

# -----------------------------------------------------------------------------
## Variable Item
##
## This class represents a single variable item in the Graph Dialogs editor.
## It allows the user to set the variable name, type and value.
# -----------------------------------------------------------------------------

## Emited when the variable is changed
signal variable_changed(name: String, type: int, value: Variant)
## Emited when the variable is renamed
signal variable_renamed(name: String)
## Emited when the remove button is pressed
signal remove_pressed()

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


func _ready() -> void:
	_set_types_dropdown()
	_set_value_field(_variable_type)
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
	
	show_modified_indicator(false)
	_on_name_changed(false) # Initialize the name input field


## Get the variable data as a dictionary
func get_variable_data() -> Dictionary:
	return {
		"name": _variable_name,
		"type": _variable_type,
		"value": _variable_value
	}


## Rename the variable item
func rename(new_name: String) -> void:
	_variable_name = new_name
	_name_input.text = new_name


## Show the modified indicator
func show_modified_indicator(show: bool) -> void:
	_modified_indicator.visible = show


## Set the types dropdown
func _set_types_dropdown() -> void:
	if $Container/TypeField.get_child_count() > 0:
		$Container/TypeField/TypeDropdown.queue_free()
	var dropdown = GraphDialogsVariableManager.get_types_dropdown()
	dropdown.select(dropdown.get_item_index(TYPE_STRING))
	dropdown.item_selected.connect(_on_type_changed)
	dropdown.fit_to_longest_item = true
	$Container/TypeField.add_child(dropdown)


## Set the value field based on the variable type
func _set_value_field(type: int) -> void:
	if _value_field.get_child_count() > 0:
		_value_field.get_child(0).queue_free()
	var field_data = GraphDialogsVariableManager.get_field_by_type(type, _on_value_changed)
	field_data.field.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	_value_field.add_child(field_data.field)
	_variable_value = field_data.default_value


## Handle the name change event
func _on_name_changed(toggled_on: bool) -> void:
	if toggled_on: return # Ignore when editing starts
	var new_name = _name_input.text.strip_edges()
	if new_name == "": new_name = "New Variable"
	_variable_name = new_name
	show_modified_indicator(true)
	variable_renamed.emit(_variable_name)
	variable_changed.emit(_variable_name, _variable_type, _variable_value)

	
## Handle the type change event
func _on_type_changed(type_index: int) -> void:
	_variable_type = $Container/TypeField/TypeDropdown.get_item_id(type_index)
	variable_changed.emit(_variable_name, _variable_type, _variable_value)
	_set_value_field(_variable_type) # Update the value field based on the new type
	show_modified_indicator(true)


## Handle the value change event
func _on_value_changed(new_value: Variant) -> void:
	_variable_value = new_value
	show_modified_indicator(true)
	variable_changed.emit(_variable_name, _variable_type, _variable_value)


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

#endregion
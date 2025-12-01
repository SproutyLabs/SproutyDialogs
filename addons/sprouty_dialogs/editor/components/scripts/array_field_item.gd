@tool
class_name EditorSproutyDialogsArrayFieldItem
extends HBoxContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs Array Field Item Component
# -----------------------------------------------------------------------------
## This component is an item field from the array field.
## It allows the user to modify the item value and type.
# -----------------------------------------------------------------------------

## Emitted when the item is modified
signal modified
## Emitted when the item is changed
signal item_changed(item: Dictionary)
## Emitted when the remove button is pressed
signal item_removed(index: int)

## Item index label
@onready var _index_label: Label = $IndexLabel
## Item remove button
@onready var _remove_button: Button = $RemoveButton

## Item type dropdown selector
var _type_dropdown: OptionButton
## Item value field
var _value_input: Control

## Current type index in the dropdown
var _type_index: int = TYPE_STRING - 1
## Current type of the item
var _item_type: int = TYPE_STRING
## Current value in the input field
var _item_value: Variant = ""


func _ready():
	_remove_button.icon = get_theme_icon("Remove", "EditorIcons")
	_remove_button.pressed.connect(_on_remove_button_pressed)

	# Set the type dropdown and connect its signal
	$TypeField.add_child(
		SproutyDialogsVariableUtils.get_types_dropdown(false, ["Variable"]))
	_type_dropdown = $TypeField/TypeDropdown
	_type_dropdown.item_selected.connect(_on_type_selected)

	# Set the string field without expandable text box
	_type_dropdown.set_item_metadata(_type_index, {"hint": PROPERTY_HINT_NONE})
	_type_dropdown.select(_type_index) # Default type (String)
	_set_value_field(_type_index) # Default type (String)


## Returns the item data as a dictionary
func get_item_data() -> Dictionary:
	return {
		"index": get_item_index(),
		"type": get_type(),
		"value": get_value(),
		"metadata": get_metadata()
	}


## Returns the current value of the item
func get_value() -> Variant:
	return _item_value


## Returns the current type of the item
func get_type() -> int:
	return _item_type


## Returns the current metadata of the item type
func get_metadata() -> Dictionary:
	var metadata = _type_dropdown.get_item_metadata(_type_index)
	return metadata if metadata else {}


## Returns the current index of the item
func get_item_index() -> int:
	return int(_index_label.text)


## Set the current index of the item
func set_item_index(index: int) -> void:
	_index_label.text = str(index)


## Set the current value of the item
func set_value(value: Variant, type: int, metadata: Dictionary) -> void:
	set_type(type, metadata)
	_item_value = value
	SproutyDialogsVariableUtils.set_field_value(_value_input, type, value)


## Set the variable type
func set_type(type: int, metadata: Dictionary) -> void:
	_type_index = _type_dropdown.get_item_index(type)
	if metadata.has("hint"): # Handle File/Dir Path types
		if metadata["hint"] == PROPERTY_HINT_FILE:
			_type_index = _type_dropdown.item_count - 2
		elif metadata["hint"] == PROPERTY_HINT_DIR:
			_type_index = _type_dropdown.item_count - 1
	
	if _type_index == -1: # Type not found, set to Nil
		_type_index = _type_dropdown.get_item_index(TYPE_NIL)
	_type_dropdown.select(_type_index)
	_set_value_field(_type_index, type)


## Set the value field based on the variable type
func _set_value_field(index: int, type: int = -1) -> void:
	# Clear previous field
	if $ValueField.get_child_count() > 0:
		var field = $ValueField.get_child(0)
		$ValueField.remove_child(field)
		field.queue_free()
	
	# Get the selected type
	if type == -1:
		type = _type_dropdown.get_item_id(index)
	var metadata = _type_dropdown.get_item_metadata(index)
	metadata = metadata if metadata else {}
	if metadata.has("hint"):
		if metadata["hint"] == PROPERTY_HINT_FILE or \
				metadata["hint"] == PROPERTY_HINT_DIR:
			type = TYPE_STRING # File/Dir Path is treated as String type
	
	# Create new field based on type
	var field_data = SproutyDialogsVariableUtils.new_field_by_type(
			type, null, metadata, _on_value_changed, modified.emit
		)
	field_data.field.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	$ValueField.add_child(field_data.field)
	_item_value = field_data.default_value
	_value_input = field_data.field
	_item_type = type


## Set the variable type and update the value field accordingly
func _on_type_selected(index: int) -> void:
	_set_value_field(index)
	_type_index = index
	modified.emit()
	item_changed.emit(get_item_data())


## Emit a signal when the item is modified
func _on_value_changed(value: Variant, type: int, field: Control) -> void:
	_item_value = value
	item_changed.emit(get_item_data())


## Emit a signal when the remove button is pressed
func _on_remove_button_pressed() -> void:
	item_removed.emit(get_item_index())

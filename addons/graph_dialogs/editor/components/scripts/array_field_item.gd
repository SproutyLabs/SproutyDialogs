@tool
class_name GraphDialogsArrayFieldItem
extends HBoxContainer

## -----------------------------------------------------------------------------
## Array Field Item Component
##
## This component is an item field from the array field.
## It allows the user to modify the item value and type.
## -----------------------------------------------------------------------------

## Emitted when the item is modified
signal item_changed(index: int, value: Variant, type: Variant)
## Emitted when the remove button is pressed
signal item_removed(index: int)

## Item value field
@onready var _value_field: GraphDialogsTypeField = $TypeField
## Item index label
@onready var _index_label: Label = $IndexLabel
## Item remove button
@onready var _remove_button: Button = $RemoveButton


func _ready():
	_remove_button.icon = get_theme_icon("Remove", "EditorIcons")
	_value_field.connect("value_changed", _on_value_changed)
	_remove_button.connect("pressed", _on_remove_button_pressed)


## Get the current value of the item
func get_value() -> Variant:
	return _value_field.get_value()


## Get the current type of the item
func get_type() -> Variant:
	return _value_field.get_type()


## Return the current index of the item
func get_item_index() -> int:
	return int(_index_label.text)


## Set the current index of the item
func set_item_index(index: int) -> void:
	_index_label.text = str(index)


## Set the current value of the item
func set_value(value: Variant, type: Variant) -> void:
	_value_field.set_value(value, type)


## Emit a signal when the item is modified
func _on_value_changed(value: Variant, type: Variant) -> void:
	item_changed.emit(get_item_index(), value, type)


## Emit a signal when the remove button is pressed
func _on_remove_button_pressed() -> void:
	item_removed.emit(get_item_index())

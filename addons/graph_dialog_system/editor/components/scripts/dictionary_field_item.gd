@tool
class_name GraphDialogsDictionaryFieldItem
extends HBoxContainer

## -----------------------------------------------------------------------------
## Dictionary Field Item Component
##
## This component is an item field from the dictionary field.
## It allows the user to modify the item key, value type and value.
## -----------------------------------------------------------------------------

## Emitted when the item is modified
signal item_changed(key: String, value: Variant, type: Variant)
## Emitted when the remove button is pressed
signal item_removed(index: int)

## Item key field
@onready var _key_field: LineEdit = $KeyInput
## Item value field
@onready var _value_field: GraphDialogsTypeField = $TypeField
## Item remove button
@onready var _remove_button: Button = $RemoveButton


func _ready():
	_remove_button.icon = get_theme_icon("Remove", "EditorIcons")
	_value_field.connect("value_changed", _on_value_changed)
	_key_field.connect("text_changed", _on_key_changed)
	_remove_button.connect("pressed", _on_remove_button_pressed)


## Get the current value of the item
func get_value() -> Variant:
	return _value_field.get_value()


## Get the current type of the item
func get_type() -> Variant:
	return _value_field.get_type()


## Get the current key of the item
func get_key() -> String:
	return _key_field.text


## Set the current key of the item
func set_key(key: String) -> void:
	_key_field.text = key


## Set the current value of the item
func set_value(value: Variant, type: Variant) -> void:
	_value_field.set_value(value, type)


## Emit a signal when the item value is modified
func _on_value_changed(value: Variant, type: Variant) -> void:
	item_changed.emit(get_key(), value, type)


## Emit a signal when the item key is modified
func _on_key_changed(key: String) -> void:
	item_changed.emit(key, _value_field.get_value(), _value_field.get_type())


## Emit a signal when the remove button is pressed
func _on_remove_button_pressed() -> void:
	item_removed.emit(get_index())
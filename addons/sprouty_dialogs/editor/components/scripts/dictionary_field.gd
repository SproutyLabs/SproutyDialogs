@tool
class_name EditorSproutyDialogsDictionaryField
extends VBoxContainer

# -----------------------------------------------------------------------------
# Dictionary Field Component
# -----------------------------------------------------------------------------
## This component is used to create a field for display a dictionary.
## It allows the user to add, remove and modify items in the dictionary.
# -----------------------------------------------------------------------------

## Emmited when the dictionary is modified
signal dictionary_changed(dictionary: Dictionary)
## Emmited when a item in the dictionary is modified
signal item_changed(key: String, value: Variant, type: Variant)
## Emmited when a new item is added to the dictionary
signal item_added(key: String, value: Variant, type: Variant)
## Emmited when an item is removed from the dictionary
signal item_removed(key: String, value: Variant, type: Variant)

## Collapse button to show/hide the dictionary items
@onready var _collapse_button = $CollapseButton
## Button to add new items to the dictionary
@onready var _add_button = $ItemsPanel/ItemsContainer/AddButton
## items container
@onready var _items_container = $ItemsPanel/ItemsContainer

## Item value field scene
var _item_field := preload("res://addons/sprouty_dialogs/editor/components/dictionary_field_item.tscn")


func _ready() -> void:
	_add_button.icon = get_theme_icon("Add", "EditorIcons")
	_items_container.get_parent().hide()


## Get the values of the array items
func get_dictionary() -> Dictionary:
	var values := {}
	for i in range(0, _items_container.get_child_count() - 1):
		var item := _items_container.get_child(i)
		values[item.get_key()] = item.get_value()
	return values


## Get the types of the array items
func get_items_types() -> Dictionary:
	var types := {}
	for i in range(0, _items_container.get_child_count() - 1):
		var item := _items_container.get_child(i)
		types[item.get_key()] = item.get_type()
	return types


## Set the array component with a given dictionary
func set_dictionary(dictionary: Dictionary, types: Dictionary) -> void:
	clear_dictionary() # Clear the current items
	for key in dictionary.keys():
		var item = _new_dictionary_item()
		item.set_value(dictionary[key], types[key])
		item.set_key(key)


## Clear the dictionary items
func clear_dictionary() -> void:
	if _items_container.get_child_count() > 1:
		for i in range(0, _items_container.get_child_count() - 1):
			var item := _items_container.get_child(i)
			_items_container.remove_child(item)
			item.queue_free()


## Add a new dictionary item
func _new_dictionary_item() -> EditorSproutyDialogsDictionaryFieldItem:
	var item = _item_field.instantiate()
	var index := _items_container.get_child_count() - 1

	item.item_removed.connect(_on_remove_button_pressed)
	item.item_changed.connect(_on_item_changed)

	_items_container.add_child(item)
	_items_container.move_child(item, index)
	_collapse_button.text = "Dictionary (size " + str(index + 1) + ")"
	return item


## Add a new item to the dictionary
func _on_add_button_pressed() -> void:
	var new_item := _new_dictionary_item()
	item_added.emit(
		new_item.get_key(),
		new_item.get_value(),
		new_item.get_type()
		)
	dictionary_changed.emit(get_dictionary())


## Remove the item at the given index
func _on_remove_button_pressed(index: int) -> void:
	var item := _items_container.get_child(index)
	_items_container.remove_child(item)
	item.queue_free()
	
	_collapse_button.text = "Dictionary (size " + str(
			_items_container.get_child_count() - 1) + ")"
	item_removed.emit(index, item.get_value(), item.get_type())
	dictionary_changed.emit(get_dictionary())


## Show/hide the dictionary items
func _on_collapse_button_toggled(toggled_on: bool) -> void:
	_items_container.get_parent().visible = toggled_on


## Emmit signals when the value of an item changes
func _on_item_changed(key: String, value: Variant, type: Variant) -> void:
	item_changed.emit(key, value, type)
	dictionary_changed.emit(get_dictionary())
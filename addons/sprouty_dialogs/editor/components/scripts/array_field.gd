@tool
class_name EditorSproutyDialogsArrayField
extends VBoxContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs Array Field Component
# -----------------------------------------------------------------------------
## This component is used to create a field for an array of data.
## It allows the user to add, remove and modify items in the array.
# -----------------------------------------------------------------------------

## Emmited when the array is modified
signal modified
## Emmited when the array is changed
signal array_changed(array: Array)
## Emmited when an item in the array is changed
signal item_changed(item: Dictionary)
## Emmited when a new item is added to the array
signal item_added(item: Dictionary)
## Emmited when an item is removed from the array
signal item_removed(item: Dictionary)

## Collapse button to show/hide the array items
@onready var _collapse_button: Button = $CollapseButton
## Button to add new items to the array
@onready var _add_button: Button = $ItemsPanel/ItemsContainer/AddButton
## Items container
@onready var _items_container: VBoxContainer = $ItemsPanel/ItemsContainer

## Array item field scene
var _item_field := preload("res://addons/sprouty_dialogs/editor/components/array_field_item.tscn")


func _ready() -> void:
	_collapse_button.toggled.connect(_on_collapse_button_toggled)
	_add_button.pressed.connect(_on_add_button_pressed)
	_add_button.icon = get_theme_icon("Add", "EditorIcons")
	_on_collapse_button_toggled(false) # Start collapsed


## Return the current array of items data
## Each item is a dictionary with the following estructure:
## {
##	   "index": int,
##     "type": int,
##     "value": Variant,
##     "metadata": Dictionary
## }
func get_array() -> Array:
	var items = []
	for child in _items_container.get_children():
		if child is EditorSproutyDialogsArrayFieldItem:
			items.append(child.get_item_data())
	return items


## Return the values of the array items
func get_items_values() -> Array:
	var values = []
	for child in _items_container.get_children():
		if child is EditorSproutyDialogsArrayFieldItem:
			values.append(child.get_value())
	return values


## Return the types of the array items
func get_items_types() -> Array:
	var types = []
	for child in _items_container.get_children():
		if child is EditorSproutyDialogsArrayFieldItem:
			types.append(child.get_type())
	return types


## Set the array component with a given array of items data
func set_array(items: Array) -> void:
	clear_array() # Clear the current items
	for i in range(0, items.size()):
		var new_item := _new_array_item()
		new_item.set_value(items[i]["value"], items[i]["type"], items[i]["metadata"])


## Clear the array items
func clear_array() -> void:
	for child in _items_container.get_children():
		if child is EditorSproutyDialogsArrayFieldItem:
			_items_container.remove_child(child)
			child.queue_free()


## Create a new array item
func _new_array_item() -> EditorSproutyDialogsArrayFieldItem:
	var item := _item_field.instantiate()
	var index := _items_container.get_child_count() - 1

	item.ready.connect(func(): item.set_item_index(index))
	item.item_removed.connect(_on_remove_button_pressed)
	item.item_changed.connect(_on_item_changed)
	item.modified.connect(modified.emit)

	_items_container.add_child(item)
	_items_container.move_child(item, index)
	_collapse_button.text = "Array (size " + str(index + 1) + ")"
	return item


## Add a new item to the array
func _on_add_button_pressed() -> void:
	var new_item := _new_array_item()
	item_added.emit(new_item.get_item_data())
	array_changed.emit(get_array())
	modified.emit()


## Remove the item at the given index
func _on_remove_button_pressed(index: int) -> void:
	var item := _items_container.get_child(index)
	var item_data = item.get_item_data()
	_items_container.remove_child(item)
	item.queue_free()

	# Update the index labels of the remaining items
	for i in range(0, _items_container.get_child_count() - 1):
		var cur_item := _items_container.get_child(i)
		cur_item.set_item_index(i)
	
	_collapse_button.text = "Array (size " + str(
			_items_container.get_child_count() - 1) + ")"
	
	item_removed.emit(item_data)
	array_changed.emit(get_array())
	modified.emit()


## Show/hide the array items
func _on_collapse_button_toggled(toggled_on: bool) -> void:
	_items_container.get_parent().visible = toggled_on


## Emmit signals when the value of an item changes
func _on_item_changed(item: Dictionary) -> void:
	item_changed.emit(item)
	array_changed.emit(get_array())
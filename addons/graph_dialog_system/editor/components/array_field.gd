@tool
class_name GraphDialogsArrayField
extends VBoxContainer

## Emmited when items in the array are modified
signal array_changed(array: Array)
## Emmited when the array is collapsed/expanded
signal array_collapsed(toggled_on: bool)
## Emmited when a item in the array is modified
signal item_changed(index: int, value: Variant, type: Variant)
## Emmited when a new item is added to the array
signal item_added(index: int, value: Variant, type: Variant)
## Emmited when an item is removed from the array
signal item_removed(index: int, value: Variant, type: Variant)

## Collapse button to show/hide the array items
@onready var _array_collapse_button = $ArrayCollapseButton
## Button to add new items to the array
@onready var _add_button = %ItemsContainer/AddButton
## items container
@onready var _items_container = %ItemsContainer

## Array item field scene
var _item_field := preload("res://addons/graph_dialog_system/editor/components/type_field.tscn")


func _ready() -> void:
	_add_button.icon = get_theme_icon("Add", "EditorIcons")
	_items_container.get_parent().hide()


## Get the values of the array items
func get_array() -> Array:
	var values = []
	for i in range(0, _items_container.get_child_count() - 1):
		var item = _items_container.get_child(i)
		values.append(item.get_value())
	return values


## Get the types of the array items
func get_items_types() -> Array:
	var types = []
	for i in range(0, _items_container.get_child_count() - 1):
		var item = _items_container.get_child(i)
		types.append(item.get_type())
	return types


## Set the array component with a given array
func set_array(items: Array, types: Array) -> void:
	# Clear the current items
	if _items_container.get_child_count() > 1:
		for i in range(0, _items_container.get_child_count() - 1):
			var item = _items_container.get_child(i)
			_items_container.remove_child(item)
			item.queue_free()

	# Add the new items
	for i in range(0, items.size()):
		var new_item = _new_array_item()
		new_item.set_value(items[i], types[i])


## Create a new array item
func _new_array_item() -> GraphDialogsTypeField:
	var new_item = _item_field.instantiate()
	var index = _items_container.get_child_count() - 1
	new_item.name = str(index)

	# Add a index label to the item
	var index_label = Label.new()
	index_label.name = "index_label"
	index_label.text = str(index)
	new_item.add_child(index_label)
	new_item.move_child(index_label, 0)

	# Add a remove button to the item
	var _remove_button = Button.new()
	_remove_button.icon = get_theme_icon("Remove", "EditorIcons")
	_remove_button.pressed.connect(_on_remove_button_pressed.bind(index))
	new_item.add_child(_remove_button)

	new_item.value_changed.connect(_on_item_value_changed.bind(index))
	_items_container.add_child(new_item)
	_items_container.move_child(new_item, index)
	_array_collapse_button.text = "Array (size " + str(index + 1) + ")"
	return new_item


## Add a new item to the array
func _on_add_button_pressed() -> void:
	var new_item = _new_array_item()
	item_added.emit(
		_items_container.get_child_count() - 1,
		new_item.get_value(),
		new_item.get_type()
		)
	array_changed.emit(get_array())


## Remove the item at the given index
func _on_remove_button_pressed(index: int) -> void:
	var item = _items_container.get_child(index)
	_items_container.remove_child(item)
	item.queue_free()

	# Update the index labels of the remaining items
	for i in range(0, _items_container.get_child_count() - 1):
		var cur_item = _items_container.get_child(i)
		cur_item.get_node("index_label").text = str(i)
	
	_array_collapse_button.text = "Array (size " + str(
			_items_container.get_child_count() - 1) + ")"
	item_removed.emit(index, item.get_value(), item.get_type())
	array_changed.emit(get_array())


## Show/hide the array items
func _on_array_collapse_button_toggled(toggled_on: bool) -> void:
	_items_container.get_parent().visible = toggled_on
	array_collapsed.emit(toggled_on)


## Emmit signals when the value of an item changes
func _on_item_value_changed(value: Variant, type: Variant, index: int) -> void:
	item_changed.emit(index, value, type)
	array_changed.emit(get_array())
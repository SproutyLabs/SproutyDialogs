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
signal modified
## Emmited when the dictionary is changed
signal dictionary_changed(dictionary: Dictionary)
## Emmited when an item in the dictionary is changed
signal item_changed(item: Dictionary)
## Emmited when a new item is added to the dictionary
signal item_added(item: Dictionary)
## Emmited when an item is removed from the dictionary
signal item_removed(item: Dictionary)

## Collapse button to show/hide the dictionary items
@onready var _collapse_button = $CollapseButton
## Button to add new items to the dictionary
@onready var _add_button = $ItemsPanel/ItemsContainer/AddButton
## Items container
@onready var _items_container = $ItemsPanel/ItemsContainer

## Dictionary item field scene
var _item_field := preload("res://addons/sprouty_dialogs/editor/components/dictionary_field_item.tscn")


func _ready() -> void:
	_collapse_button.toggled.connect(_on_collapse_button_toggled)
	_add_button.pressed.connect(_on_add_button_pressed)
	_add_button.icon = get_theme_icon("Add", "EditorIcons")
	_on_collapse_button_toggled(false) # Start collapsed


## Return the current dictionary of items data
## Each item is a dictionary with the following estructure:
## {
##	   "key": String,
##     "type": int,
##     "value": Variant,
##     "metadata": Dictionary
## }
func get_dictionary() -> Dictionary:
	var items := {}
	for child in _items_container.get_children():
		if child is EditorSproutyDialogsDictionaryFieldItem:
			items[child.get_key()] = child.get_item_data()
	return items


## Return the keys of the dictionary items
func get_keys() -> Array:
	var keys := []
	for child in _items_container.get_children():
		if child is EditorSproutyDialogsDictionaryFieldItem:
			keys.append(child.get_key())
	return keys


## Return the values of the dictionary items
func get_items_values() -> Dictionary:
	var values := {}
	for child in _items_container.get_children():
		if child is EditorSproutyDialogsDictionaryFieldItem:
			values[child.get_key()] = child.get_value()
	return values


## Return the types of the dictionary items
func get_items_types() -> Dictionary:
	var types := {}
	for child in _items_container.get_children():
		if child is EditorSproutyDialogsDictionaryFieldItem:
			types[child.get_key()] = child.get_type()
	return types


## Set the array component with a given dictionary
func set_dictionary(items: Dictionary) -> void:
	clear_dictionary() # Clear the current items
	for key in items.keys():
		var item = _new_dictionary_item()
		item.set_value(items[key]["value"], items[key]["type"], items[key]["metadata"])
		item.set_key(key)


## Clear the dictionary items
func clear_dictionary() -> void:
	for child in _items_container.get_children():
		if child is EditorSproutyDialogsDictionaryFieldItem:
			_items_container.remove_child(child)
			child.queue_free()


## Add a new dictionary item
func _new_dictionary_item() -> EditorSproutyDialogsDictionaryFieldItem:
	var item = _item_field.instantiate()
	var index := _items_container.get_child_count() - 1

	item.key_modified.connect(_on_key_modified.bind(item))
	item.item_removed.connect(_on_remove_button_pressed)
	item.item_changed.connect(_on_item_changed)
	item.modified.connect(modified.emit)

	_items_container.add_child(item)
	_items_container.move_child(item, index)
	_collapse_button.text = "Dictionary (size " + str(index + 1) + ")"
	item.set_key(SproutyDialogsFileUtils.ensure_unique_name("", get_keys(), "None"))
	return item


## Emmit signals when the value of an item changes
func _on_item_changed(item: Dictionary) -> void:
	item_changed.emit(item)
	dictionary_changed.emit(get_dictionary())


## Handle when an item key is changed
func _on_key_modified(key: String, item: EditorSproutyDialogsDictionaryFieldItem) -> void:
	var keys = get_keys()
	keys.erase(key)

	var unique_key = SproutyDialogsFileUtils.ensure_unique_name(key, keys, "None")
	if key != unique_key:
		item.set_key(unique_key)
	
	item_changed.emit(item.get_item_data())
	dictionary_changed.emit(get_dictionary())


## Add a new item to the dictionary
func _on_add_button_pressed() -> void:
	var new_item := _new_dictionary_item()
	item_added.emit(new_item.get_item_data())
	dictionary_changed.emit(get_dictionary())
	modified.emit()


## Remove the item at the given index
func _on_remove_button_pressed(index: int) -> void:
	var item := _items_container.get_child(index)
	var item_data = item.get_item_data()
	_items_container.remove_child(item)
	item.queue_free()
	
	_collapse_button.text = "Dictionary (size " + str(
			_items_container.get_child_count() - 1) + ")"
	
	item_removed.emit(item_data)
	dictionary_changed.emit(get_dictionary())
	modified.emit()


## Show/hide the dictionary items
func _on_collapse_button_toggled(toggled_on: bool) -> void:
	_items_container.get_parent().visible = toggled_on
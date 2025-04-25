@tool
class_name GraphDialogsArrayField
extends VBoxContainer

## Emmited when elements in the array are modified
signal array_changed(array: Array)
## Emmited when the array is collapsed/expanded
signal array_collapsed(toggled_on: bool)
## Emmited when a element in the array is modified
signal element_changed(index: int, element: Variant)
## Emmited when a new element is added to the array
signal element_added(index: int, element: Variant)
## Emmited when an element is removed from the array
signal element_removed(index: int, element: Variant)

## Collapse button to show/hide the array items
@onready var _array_collapse_button = $ArrayCollapseButton
## Button to add new elements to the array
@onready var _add_button = $ElementsContainer/AddButton
## Elements container
@onready var _elements_container = $ElementsContainer

## Array element field scene
var _element_field := preload("res://addons/graph_dialog_system/editor/components/type_field.tscn")


func _ready() -> void:
	_add_button.icon = get_theme_icon("Add", "EditorIcons")
	_elements_container.hide()


## Get the values of the array elements
func get_array_values() -> Array:
	var values = []
	for i in range(0, _elements_container.get_child_count() - 1):
		var element = _elements_container.get_child(i)
		values.append(element.get_value())
	return values


## Get the types of the array elements
func get_array_types() -> Array:
	var types = []
	for i in range(0, _elements_container.get_child_count() - 1):
		var element = _elements_container.get_child(i)
		types.append(element.get_type())
	return types


## Set the array component with a given array
func set_array(elements: Array) -> void:
	# Clear the current elements
	for i in range(0, _elements_container.get_child_count() - 1):
		var element = _elements_container.get_child(i)
		_elements_container.remove_child(element)
		element.queue_free()

	# Add the new elements
	for i in range(0, elements.size()):
		var new_element = _new_array_element()
		match typeof(elements[i]): # Set the type of the element
			TYPE_FLOAT:
				# If a float does not have decimals, set it as int
				if step_decimals(elements[i]) == 0:
					new_element.set_type(TYPE_INT)
			_:
				new_element.set_type(typeof(elements[i]))
		new_element.set_value(elements[i])


## Create a new array element
func _new_array_element() -> GraphDialogsTypeField:
	var new_element = _element_field.instantiate()
	var index = _elements_container.get_child_count() - 1
	new_element.name = str(index)

	# Add a index label to the element
	var index_label = Label.new()
	index_label.name = "index_label"
	index_label.text = str(index)
	new_element.add_child(index_label)
	new_element.move_child(index_label, 0)

	# Add a remove button to the element
	var _remove_button = Button.new()
	_remove_button.icon = get_theme_icon("Remove", "EditorIcons")
	_remove_button.pressed.connect(_on_remove_button_pressed.bind(index))
	new_element.add_child(_remove_button)

	new_element.value_changed.connect(_on_element_value_changed.bind(index))
	_elements_container.add_child(new_element)
	_elements_container.move_child(new_element, index)
	_array_collapse_button.text = "Array (size " + str(index + 1) + ")"
	return new_element


## Add a new element to the array
func _on_add_button_pressed() -> void:
	var new_element = _new_array_element()
	element_added.emit(
		_elements_container.get_child_count() - 1,
		new_element.get_value(),
		new_element.get_type()
		)
	array_changed.emit(get_array_values())


## Remove the element at the given index
func _on_remove_button_pressed(index: int) -> void:
	var element = _elements_container.get_child(index)
	_elements_container.remove_child(element)
	element.queue_free()

	# Update the index labels of the remaining elements
	for i in range(0, _elements_container.get_child_count() - 1):
		var cur_element = _elements_container.get_child(i)
		cur_element.get_node("index_label").text = str(i)
	
	_array_collapse_button.text = "Array (size " + str(
			_elements_container.get_child_count() - 1) + ")"
	element_removed.emit(index, element.get_value(), element.get_type())
	array_changed.emit(get_array_values())


## Show/hide the array elements
func _on_array_collapse_button_toggled(toggled_on: bool) -> void:
	_elements_container.visible = toggled_on
	array_collapsed.emit(toggled_on)


## Emmit signals when the value of an element changes
func _on_element_value_changed(value: Variant, type: int, index: int) -> void:
	element_changed.emit(index, value, type)
	array_changed.emit(get_array_values())
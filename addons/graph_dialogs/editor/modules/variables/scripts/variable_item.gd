@tool
class_name GraphDialogsVariableItem
extends MarginContainer

# -----------------------------------------------------------------------------
## Variable Field
##
## This class represents a field for editing a variable in the Graph Dialogs editor.
# It allows the user to set the variable name, type, and value.
# -----------------------------------------------------------------------------

## Emited when the variable is changed
signal variable_changed(name: String, type: int, value: Variant)
## Emited when the remove button is pressed
signal remove_pressed(variable_name: String)

## The variable name
@export var variable_name: String = "New Variable"
## The variable type
@export var variable_type: int = TYPE_STRING
## The variable value
@export var variable_value: Variant = ""


func _ready() -> void:
	_set_types_dropdown()
	_set_value_field(variable_type)
	$Container/RemoveButton.icon = get_theme_icon("Remove", "EditorIcons")
	$Container/RemoveButton.pressed.connect(remove_pressed.emit.bind(variable_name))
	$Container/NameInput.text_changed.connect(_on_name_changed)


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
	if $Container/ValueField.get_child_count() > 0:
		$Container/ValueField.get_child(0).queue_free()
	var field = GraphDialogsVariableManager.get_field_by_type(type, _on_value_changed)
	field.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	$Container/ValueField.add_child(field)


## Handle the name change event
func _on_name_changed(new_name: String) -> void:
	variable_name = new_name
	variable_changed.emit(variable_name, variable_type, variable_value)
	print("Variable changed: ", variable_name, " (", variable_type, ") = ", variable_value)


## Handle the type change event
func _on_type_changed(type_index: int) -> void:
	variable_type = $Container/TypeField/TypeDropdown.get_item_id(type_index)
	variable_changed.emit(variable_name, variable_type, variable_value)
	_set_value_field(variable_type) # Update the value field based on the new type
	print("Variable changed: ", variable_name, " (", variable_type, ") = ", variable_value)


## Handle the value change event
func _on_value_changed(new_value: Variant) -> void:
	variable_value = new_value
	variable_changed.emit(variable_name, variable_type, variable_value)
	print("Variable changed: ", variable_name, " (", variable_type, ") = ", variable_value)
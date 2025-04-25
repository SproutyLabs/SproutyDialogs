@tool
class_name GraphDialogsTypeField
extends HBoxContainer

## -----------------------------------------------------------------------------
## Type Field Component
##
## This component is used to create a field for a specific type of data.
## It allows the user to select a type from a dropdown menu and then
## provides a field for that type.
## -----------------------------------------------------------------------------

## Emitted when the input value is changed
signal value_changed(value: Variant, type: int)
## Emitted when the type is changed
signal type_changed(value: int)

## Types dropdown menu
@onready var _types_dropdown = $TypesDropdown
## Field container for the selected type
@onready var _field_container = $FieldContainer

## Types and their corresponding enumeration from GlobalScope
var _supported_types = {
	"Nil": TYPE_NIL,
	"bool": TYPE_BOOL,
	"int": TYPE_INT,
	"float": TYPE_FLOAT,
	"String": TYPE_STRING,
	"Vector2": TYPE_VECTOR2,
	"Vector3": TYPE_VECTOR3,
	"Vector4": TYPE_VECTOR4,
	"Color": TYPE_COLOR,
	"Dictionary": TYPE_DICTIONARY,
	"Array": TYPE_ARRAY
}

## Current value in the field
var current_value: Variant = null
## Current type in the field
var current_type: int = TYPE_NIL


func _ready() -> void:
	_setup_types_dropdown()

#region === Getters and Setters ================================================

## Return the current type of the field
func get_type() -> int:
	return current_type


## Return the current value of the field
func get_value() -> Variant:
	return current_value


## Set the type of the field
func set_type(type: int) -> void:
	_types_dropdown.selected_index = type
	_on_types_dropdown_item_selected(type)


## Set the value of the field
func set_value(value: Variant) -> void:
	if typeof(value) != _types_dropdown.selected_index:
		printerr("[Graph Dialogs] Expected value of type %s, but got %s" % [
			_types_dropdown.selected_index,
			typeof(value)
		])
		return
	current_value = value
	match _types_dropdown.selected_index:
		TYPE_BOOL:
			_field_container.get_child(0).pressed = value
		TYPE_INT:
			_field_container.get_child(0).value = value
		TYPE_FLOAT:
			_field_container.get_child(0).value = value
		TYPE_STRING:
			_field_container.get_child(0).text = value
		TYPE_VECTOR2:
			_field_container.get_child(1).value = value.x
			_field_container.get_child(3).value = value.y
		TYPE_VECTOR3:
			_field_container.get_child(1).value = value.x
			_field_container.get_child(3).value = value.y
			_field_container.get_child(5).value = value.z
		TYPE_VECTOR4:
			_field_container.get_child(1).value = value.x
			_field_container.get_child(3).value = value.y
			_field_container.get_child(5).value = value.z
			_field_container.get_child(7).value = value.w
		TYPE_COLOR:
			_field_container.get_child(0).color = value
		TYPE_DICTIONARY:
			pass
		TYPE_ARRAY:
			pass

#endregion

## Setup the dropdown menu with types
func _setup_types_dropdown() -> void:
	_types_dropdown.clear()
	var index = 0
	for type in _supported_types.keys():
		_types_dropdown.add_icon_item(get_theme_icon(type, "EditorIcons"), type)
		_types_dropdown.set_item_id(index, _supported_types[type])
		index += 1
	_types_dropdown.selected = TYPE_NIL
	_on_types_dropdown_item_selected(TYPE_NIL)
	if not _types_dropdown.is_connected("item_selected", _on_types_dropdown_item_selected):
		_types_dropdown.item_selected.connect(_on_types_dropdown_item_selected)


## Update the field container based on the selected type
func _on_types_dropdown_item_selected(index: int) -> void:
	var type = _types_dropdown.get_item_id(index)
	_clear_field()

	match type:
		TYPE_BOOL:
			var field = CheckBox.new()
			field.toggled.connect(_on_field_value_changed.bind(type))
			_field_container.add_child(field)
			current_value = false
		
		TYPE_INT:
			var field = SpinBox.new()
			field.step = 1
			field.allow_greater = true
			field.allow_lesser = true
			field.size_flags_horizontal = SIZE_EXPAND_FILL
			field.value_changed.connect(_on_field_value_changed.bind(type))
			_field_container.add_child(field)
			current_value = 0
		
		TYPE_FLOAT:
			var field = SpinBox.new()
			field.step = 0.01
			field.allow_greater = true
			field.allow_lesser = true
			field.size_flags_horizontal = SIZE_EXPAND_FILL
			field.value_changed.connect(_on_field_value_changed.bind(type))
			_field_container.add_child(field)
			current_value = 0.0
		
		TYPE_STRING:
			var field = LineEdit.new()
			field.size_flags_horizontal = SIZE_EXPAND_FILL
			field.text_changed.connect(_on_field_value_changed.bind(type))
			_field_container.add_child(field)
			current_value = ""
		
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			var vector_n := int(type_string(type)[-1])
			var components_names = ["x", "y", "z", "w"]
			# Create the fields for each component of the vector
			for i in range(0, vector_n):
				var label = Label.new()
				label.text = components_names[i]
				_field_container.add_child(label)
				var field = SpinBox.new()
				field.step = 0.01
				field.allow_greater = true
				field.allow_lesser = true
				field.size_flags_horizontal = SIZE_EXPAND_FILL
				field.value_changed.connect(
						_on_field_value_changed.bind(type, components_names[i]))
				_field_container.add_child(field)
			current_value = Vector2.ZERO if vector_n == 2 else (
					Vector3.ZERO if vector_n == 3 else Vector4.ZERO)
		
		TYPE_COLOR:
			var field = ColorPickerButton.new()
			field.size_flags_horizontal = SIZE_EXPAND_FILL
			field.color_changed.connect(_on_field_value_changed.bind(type))
			_field_container.add_child(field)
			current_value = field.color
		
		TYPE_DICTIONARY:
			current_value = {}
			pass
		
		TYPE_ARRAY:
			var field = load("addons/graph_dialog_system/editor/components/array_field.tscn").instantiate()
			field.size_flags_horizontal = SIZE_EXPAND_FILL
			field.array_changed.connect(_on_field_value_changed.bind(type))
			_field_container.add_child(field)
			current_value = []
		_:
			var field = LineEdit.new()
			field.text = "<null>"
			field.editable = false
			field.size_flags_horizontal = SIZE_EXPAND_FILL
			_field_container.add_child(field)
			current_value = null
	
	current_type = type
	emit_signal("type_changed", index)


## Clear the field container
func _clear_field() -> void:
	for child in _field_container.get_children():
		child.queue_free()


## Called when the field value is changed
func _on_field_value_changed(value: Variant, type: int, component: String = "") -> void:
	# If is changing a vector component, update the vector with the value
	if type == TYPE_VECTOR2 or type == TYPE_VECTOR3 or type == TYPE_VECTOR4:
		match component:
			"x":
				current_value.x = value
			"y":
				current_value.y = value
			"z":
				current_value.z = value
			"w":
				current_value.w = value
	else:
		current_value = value
	
	emit_signal("value_changed", value, type)
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
signal value_changed(value: Variant, type: Variant)
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
var _current_value: Variant = null
## Current type in the field
var _current_type: Variant = null
## Current field in the field
var _current_field: Variant = null

## Array field scene
var _array_field := preload("res://addons/graph_dialog_system/editor/components/array_field.tscn")


func _ready() -> void:
	_setup_types_dropdown()


## Return the current type of the field
func get_type() -> Variant:
	return _current_type


## Return the current value of the field
func get_value() -> Variant:
	return _current_value


## Set the type of the field
func set_type(type: Variant) -> void:
	_types_dropdown.selected = _types_dropdown.get_item_index(_get_real_type(type))
	_update_field_type(type)


## Set the value of the field
func set_value(value: Variant, type: Variant) -> void:
	var field_type: int = _get_real_type(type)
	_current_value = value
	set_type(type)
	match field_type:
		TYPE_BOOL:
			_current_field.button_pressed = value
		TYPE_INT:
			_current_field.value = value
		TYPE_FLOAT:
			_current_field.value = value
		TYPE_STRING:
			_current_field.text = value
		TYPE_VECTOR2:
			_current_field.value = value.x
			_current_field.value = value.y
		TYPE_VECTOR3:
			_current_field.get_child(1).value = value.x
			_current_field.get_child(3).value = value.y
			_current_field.get_child(5).value = value.z
		TYPE_VECTOR4:
			_current_field.get_child(1).value = value.x
			_current_field.get_child(3).value = value.y
			_current_field.get_child(5).value = value.z
			_current_field.get_child(7).value = value.w
		TYPE_COLOR:
			_current_field.color = value
		TYPE_DICTIONARY:
			pass
		TYPE_ARRAY:
			_current_field.set_array(value, type)


## Setup the dropdown menu with types
func _setup_types_dropdown() -> void:
	_types_dropdown.clear()
	var index := 0
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
	_update_field_type(type)
	emit_signal("type_changed", type)


## Update the field by type
func _update_field_type(type: Variant) -> void:
	var field_type: int = _get_real_type(type)
	var field = null
	_clear_field()
	match field_type:
		TYPE_BOOL:
			field = CheckBox.new()
			field.toggled.connect(_on_field_value_changed.bind(type))
			_field_container.add_child(field)
			_current_value = false
		
		TYPE_INT:
			field = SpinBox.new()
			field.step = 1
			field.allow_greater = true
			field.allow_lesser = true
			field.size_flags_horizontal = SIZE_EXPAND_FILL
			field.value_changed.connect(_on_field_value_changed.bind(type))
			_field_container.add_child(field)
			_current_value = 0
		
		TYPE_FLOAT:
			field = SpinBox.new()
			field.step = 0.01
			field.allow_greater = true
			field.allow_lesser = true
			field.size_flags_horizontal = SIZE_EXPAND_FILL
			field.value_changed.connect(_on_field_value_changed.bind(type))
			_field_container.add_child(field)
			_current_value = 0.0
		
		TYPE_STRING:
			field = LineEdit.new()
			field.size_flags_horizontal = SIZE_EXPAND_FILL
			field.text_changed.connect(_on_field_value_changed.bind(type))
			_field_container.add_child(field)
			_current_value = ""
		
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_VECTOR4:
			var vector_n := int(type_string(type)[-1])
			var components_names = ["x", "y", "z", "w"]
			# Create the fields for each component of the vector
			for i in range(0, vector_n):
				var label = Label.new()
				label.text = components_names[i]
				_field_container.add_child(label)
				var n_field = SpinBox.new()
				n_field.step = 0.01
				n_field.allow_greater = true
				n_field.allow_lesser = true
				n_field.size_flags_horizontal = SIZE_EXPAND_FILL
				n_field.value_changed.connect(
						_on_field_value_changed.bind(type, components_names[i]))
				_field_container.add_child(n_field)
			_current_value = Vector2.ZERO if vector_n == 2 else (
					Vector3.ZERO if vector_n == 3 else Vector4.ZERO)
			field = _field_container
		
		TYPE_COLOR:
			field = ColorPickerButton.new()
			field.size_flags_horizontal = SIZE_EXPAND_FILL
			field.color_changed.connect(_on_field_value_changed.bind(type))
			_field_container.add_child(field)
			_current_value = field.color
		
		TYPE_DICTIONARY:
			_current_value = {}
			pass
		
		TYPE_ARRAY:
			field = _array_field.instantiate()
			field.size_flags_horizontal = SIZE_EXPAND_FILL
			field.array_changed.connect(_on_field_value_changed.bind(type))
			_field_container.add_child(field)
			_current_value = []
		_:
			field = LineEdit.new()
			field.text = "<null>"
			field.editable = false
			field.size_flags_horizontal = SIZE_EXPAND_FILL
			_field_container.add_child(field)
			_current_value = null
	
	_current_field = field
	_current_type = type


## Return the type of the field
## When we have a field with elements, like a dictionary or an array
## its type is also a dictionary or an array with the types of the elements,
## so we need to get the real type of the field (DICTIONARY or ARRAY)
func _get_real_type(type: Variant) -> int:
	var real_type: int = 0
	if typeof(type) == TYPE_DICTIONARY:
		real_type = TYPE_DICTIONARY
	elif typeof(type) == TYPE_ARRAY:
		real_type = TYPE_ARRAY
	else:
		real_type = type
	return real_type


## Clear the field container
func _clear_field() -> void:
	for child in _field_container.get_children():
		child.queue_free()


## Called when the field value is changed
func _on_field_value_changed(value: Variant, type: Variant, component: String = "") -> void:
	# If is changing a vector component, update the vector with the value
	var field_type = _get_real_type(type)
	if field_type == TYPE_VECTOR2 or field_type == TYPE_VECTOR3 or field_type == TYPE_VECTOR4:
		match component:
			"x":
				_current_value.x = value
			"y":
				_current_value.y = value
			"z":
				_current_value.z = value
			"w":
				_current_value.w = value
	else:
		_current_value = value
	
	emit_signal("value_changed", value, type)
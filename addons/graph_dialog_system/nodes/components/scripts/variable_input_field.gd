@tool
class_name VariableInputField
extends Control

## -----------------------------------------------------------------------------
## Variable Input Field
##
## Component to input variables of different types.
## -----------------------------------------------------------------------------

## Variable types
enum Type {STR, INT, FLOAT, BOOL}

## String input field
@onready var _string_value: LineEdit = $StringValue
## Integer input field
@onready var _int_value: SpinBox = $IntValue
## Float input field
@onready var _float_value: SpinBox = $FloatValue
## Boolean input field
@onready var _bool_value: OptionButton = $BoolValue

## Current variable type
@onready var _var_type: Type = 0
## Current variable input field
@onready var _current_field: Control = _string_value


func _ready() -> void:
	## Hide all input fields
	for child in get_children():
		child.visible = false
	update_var_field() # Update active input field


## Get input field value
func get_value() -> Variant:
	match _var_type:
		Type.STR:
			return _string_value.text
		Type.INT:
			return _int_value.value
		Type.FLOAT:
			return _float_value.value
		Type.BOOL:
			return _bool_value.selected
		_:
			return null


## Set input field value
func set_value(value: Variant) -> void:
	match _var_type:
		Type.STR:
			_string_value.text = value
		Type.INT:
			_int_value.value = value
		Type.FLOAT:
			_float_value.value = value
		Type.BOOL:
			_bool_value.selected = value


## Change variable type
func change_var_type(new_type: Type) -> void:
	_var_type = new_type
	update_var_field()


## Update active input field
func update_var_field() -> void:
	match _var_type:
		Type.STR:
			_active_input_field(_string_value)
		Type.INT:
			_active_input_field(_int_value)
		Type.FLOAT:
			_active_input_field(_float_value)
		Type.BOOL:
			_active_input_field(_bool_value)


## Activate an input field
func _active_input_field(input_field: Control) -> void:
	input_field.visible = true
	if _current_field != input_field:
		_current_field.visible = false
	_current_field = input_field
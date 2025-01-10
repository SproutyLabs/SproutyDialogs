@tool
class_name VariableInputField
extends Control

enum Type {STR, INT, FLOAT, BOOL}

@onready var var_type : Type = 0
@onready var current_field : Control = $StringValue

func _ready() -> void:
	for child in get_children():
		child.visible = false
	update_var_field()

func get_value():
	# Get input field value
	match var_type:
		Type.STR:
			return $StringValue.text
		Type.INT:
			return $IntValue.value
		Type.FLOAT:
			return $FloatValue.value
		Type.BOOL:
			return $BoolValue.selected

func set_value(value) -> void:
	# Set input field value
	match var_type:
		Type.STR:
			$StringValue.text = value
		Type.INT:
			$IntValue.value = value
		Type.FLOAT:
			$FloatValue.value = value
		Type.BOOL:
			$BoolValue.selected = value

func change_var_type( new_type : Type) -> void:
	# Change current variable type
	var_type = new_type
	update_var_field()

func update_var_field() -> void:
	# Update active input field
	match var_type:
		Type.STR:
			$StringValue.visible = true
			if current_field != $StringValue:
				current_field.visible = false
			current_field = $StringValue
		Type.INT:
			$IntValue.visible = true
			if current_field != $IntValue:
				current_field.visible = false
			current_field = $IntValue
		Type.FLOAT:
			$FloatValue.visible = true
			if current_field != $FloatValue:
				current_field.visible = false
			current_field = $FloatValue
		Type.BOOL:
			$BoolValue.visible = true
			if current_field != $BoolValue:
				current_field.visible = false
			current_field = $BoolValue
		

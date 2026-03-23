@tool
class_name EditorSproutyDialogsConditionsContainer
extends VBoxContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs Conditions Container Component
# -----------------------------------------------------------------------------

signal modified(modified: bool)

var collapse_up_icon = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-up.svg")
var collapse_down_icon = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-down.svg")

var _values_modified: Array[bool] = [false, false]
var _type_dropdowns: Array = [null, null]
var _value_inputs: Array = [null, null]
var _var_values: Array = ["", ""]
var _type_indexes: Array[int] = [40, 40]
var _operator_index: int = 0

@onready var _conditions_box: Container = %ConditionBoxes
@onready var _check_box: CheckBox = $Header/CheckBox
@onready var _operator_dropdown: OptionButton = $ScrollContainer/ConditionBoxes/Container/OperatorDropdown
@onready var _visibility_dropdown: OptionButton = $ScrollContainer/ConditionBoxes/Container/HBoxContainer/OptionButton


func _ready():
	if _conditions_box.get_parent() != self:
		_conditions_box.get_parent().visible = false
	_conditions_box.visible = false

	_set_type_dropdown($ScrollContainer/ConditionBoxes/Container/FirstVar/TypeField, 0)
	_set_type_dropdown($ScrollContainer/ConditionBoxes/Container/SecondVar/TypeField, 1)
	_check_box.toggled.connect(func(_pressed: bool): modified.emit(true))
	_operator_dropdown.item_selected.connect(func(index: int):
		_operator_index = index
		modified.emit(true)
	)
	_visibility_dropdown.item_selected.connect(func(_index: int): modified.emit(true))


func _set_type_dropdown(dropdown_field: Node, field_index: int) -> void:
	var types_dropdown = SproutyDialogsVariableUtils.get_types_dropdown(
		true, ["Nil", "Dictionary", "Array"]
	)
	dropdown_field.add_child(types_dropdown)
	_type_dropdowns[field_index] = dropdown_field.get_node("TypeDropdown")
	_type_dropdowns[field_index].item_selected.connect(_on_type_selected.bind(field_index))
	_type_dropdowns[field_index].select(0)
	_set_value_field(0, field_index)


func _set_value_field(type_index: int, field_index: int) -> void:
	var type = _type_dropdowns[field_index].get_item_id(type_index)
	var value_field = $ScrollContainer/ConditionBoxes/Container/FirstVar/ValueField if field_index == 0 else $ScrollContainer/ConditionBoxes/Container/SecondVar/ValueField

	var metadata = _type_dropdowns[field_index].get_item_metadata(type_index)
	if metadata.has("hint"):
		if metadata["hint"] == PROPERTY_HINT_FILE or metadata["hint"] == PROPERTY_HINT_DIR or metadata["hint"] == PROPERTY_HINT_EXPRESSION:
			type = TYPE_STRING

	if value_field.get_child_count() > 0:
		var field = value_field.get_child(0)
		value_field.remove_child(field)
		field.queue_free()

	var field_data = SproutyDialogsVariableUtils.new_field_by_type(
		type, null, _type_dropdowns[field_index].get_item_metadata(type_index),
		_on_value_changed.bind(field_index), _on_value_input_modified.bind(field_index)
	)
	field_data.field.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	value_field.add_child(field_data.field)
	_value_inputs[field_index] = field_data.field
	_var_values[field_index] = field_data.default_value
	_type_indexes[field_index] = type_index


func _on_type_selected(type_index: int, field_index: int) -> void:
	_set_value_field(type_index, field_index)
	modified.emit(true)


func _on_value_changed(value: Variant, type: int, field: Control, field_index: int) -> void:
	_var_values[field_index] = value
	modified.emit(true)


func get_data() -> Dictionary:
	return {
		"enabled": $Header/CheckBox.button_pressed,
		"first_var": {
			"type": _type_dropdowns[0].get_item_id(_type_dropdowns[0].selected),
			"metadata": _type_dropdowns[0].get_item_metadata(_type_dropdowns[0].selected),
			"value": _var_values[0]
		},
		"second_var": {
			"type": _type_dropdowns[1].get_item_id(_type_dropdowns[1].selected),
			"metadata": _type_dropdowns[1].get_item_metadata(_type_dropdowns[1].selected),
			"value": _var_values[1]
		},
		"operator": $ScrollContainer/ConditionBoxes/Container/OperatorDropdown.get_item_id($ScrollContainer/ConditionBoxes/Container/OperatorDropdown.selected),
		"visibility": _visibility_dropdown.get_item_id(_visibility_dropdown.selected)
	}


func set_data(data: Dictionary) -> void:
	$Header/CheckBox.button_pressed = data.get("enabled", false)
	load_type_data(data, 0)
	load_type_data(data, 1)
	$ScrollContainer/ConditionBoxes/Container/OperatorDropdown.select(
		$ScrollContainer/ConditionBoxes/Container/OperatorDropdown.get_item_index(data.get("operator", 0))
	)
	_set_field_value(data["first_var"]["value"], data["first_var"]["type"], 0)
	_set_field_value(data["second_var"]["value"], data["second_var"]["type"], 1)
	_var_values = [data["first_var"]["value"], data["second_var"]["value"]]
	_operator_index = $ScrollContainer/ConditionBoxes/Container/OperatorDropdown.selected
	_visibility_dropdown.select(data.get("visibility", 0))


func load_type_data(data: Dictionary, field_index: int) -> void:
	var key = "first_var" if field_index == 0 else "second_var"
	var type_index = _type_dropdowns[field_index].get_item_index(data[key]["type"])

	if data[key]["metadata"].has("hint"):
		if data[key]["metadata"]["hint"] == PROPERTY_HINT_EXPRESSION:
			type_index = _type_dropdowns[field_index].item_count - 3
		elif data[key]["metadata"]["hint"] == PROPERTY_HINT_FILE:
			type_index = _type_dropdowns[field_index].item_count - 2
		elif data[key]["metadata"]["hint"] == PROPERTY_HINT_DIR:
			type_index = _type_dropdowns[field_index].item_count - 1

	_type_dropdowns[field_index].select(type_index)
	_set_value_field(type_index, field_index)
	_type_indexes[field_index] = type_index


func _set_field_value(value: Variant, type: int, field_index: int) -> void:
	_var_values[field_index] = value
	SproutyDialogsVariableUtils.set_field_value(_value_inputs[field_index], type, value)


func _on_value_input_modified(field_index: int) -> void:
	if _values_modified[field_index]:
		_values_modified[field_index] = false
		modified.emit(true)


func _on_expand_button_toggled(toggled_on: bool) -> void:
	if _conditions_box.get_parent() != self:
		_conditions_box.get_parent().visible = toggled_on

	_conditions_box.visible = toggled_on
	$Header/ExpandButton.icon = collapse_up_icon if toggled_on else collapse_down_icon

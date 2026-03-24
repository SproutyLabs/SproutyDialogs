@tool
class_name EditorSproutyDialogsConditionsContainer
extends VBoxContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs Conditions Container Component
# -----------------------------------------------------------------------------
## Component that allows to set a condition to change the visibility of a dialog
## option in the options node.
##
## If the condition is not meet, you can set the option as "hidden" or "diabled".
# -----------------------------------------------------------------------------

## Emitted when press the expand button in a text box field
signal open_text_editor(text_box: TextEdit)
## Emitted when a text box field gains focus and should update the text editor
signal update_text_editor(text_box: TextEdit)
## Emitted when the condition is modified
signal modified(modified: bool)

## Components
@onready var _conditions_box: Container = %ConditionBoxes
@onready var _check_box: CheckBox = $Header/CheckBox
@onready var _operator_dropdown: OptionButton = $ScrollContainer/ConditionBoxes/Container/OperatorDropdown
@onready var _visibility_dropdown: OptionButton = $ScrollContainer/ConditionBoxes/Container/HBoxContainer/OptionButton

## Both variable type dropdown selectors
var _type_dropdowns: Array = [null, null]
## Both variable value input fields
var _value_inputs: Array = [null, null]
## Variable values for the condition
var _var_values: Array = ["", ""]

## Undo redo variables
var _type_indexes: Array[int] = [40, 40]
var _operator_index: int = 0
var _visibility_index: int = 0
var _condition_enabled: bool = false

## Flag to indicate if the value has been modified (for UndoRedo)
var _values_modified: Array[bool] = [false, false]

## Collapse icons
var collapse_up_icon = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-up.svg")
var collapse_down_icon = preload("res://addons/sprouty_dialogs/editor/icons/interactable/collapse-down.svg")

## UndoRedo manager
var undo_redo: EditorUndoRedoManager


func _ready():
	if _conditions_box.get_parent() != self:
		_conditions_box.get_parent().visible = false
	_conditions_box.visible = false

	_set_type_dropdown($ScrollContainer/ConditionBoxes/Container/FirstVar/TypeField, 0)
	_set_type_dropdown($ScrollContainer/ConditionBoxes/Container/SecondVar/TypeField, 1)
	_check_box.toggled.connect(_on_enable_condition_toggled)
	_operator_dropdown.item_selected.connect(_on_operator_selected)
	_visibility_dropdown.item_selected.connect(_on_visibility_changed)


## Set the type dropdowns and connect their signals
func _set_type_dropdown(dropdown_field: Node, field_index: int) -> void:
	var types_dropdown = SproutyDialogsVariableUtils.get_types_dropdown(
		false, ["Nil", "Dictionary", "Array"]
	)
	dropdown_field.add_child(types_dropdown)
	_type_dropdowns[field_index] = dropdown_field.get_node("TypeDropdown")
	_type_dropdowns[field_index].item_selected.connect(_on_type_selected.bind(field_index))
	_type_dropdowns[field_index].select(0)
	_set_value_field(0, field_index)


#region === Node Data ==========================================================

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
		"operator": _operator_dropdown.get_item_id(_operator_dropdown.selected),
		"visibility": _visibility_dropdown.get_item_id(_visibility_dropdown.selected)
	}


func set_data(data: Dictionary) -> void:
	$Header/CheckBox.button_pressed = data.get("enabled", false)
	load_type_data(data, 0)
	load_type_data(data, 1)
	_operator_dropdown.select(
		_operator_dropdown.get_item_index(data.get("operator", 0))
	)
	_set_field_value(data["first_var"]["value"], data["first_var"]["type"], 0)
	_set_field_value(data["second_var"]["value"], data["second_var"]["type"], 1)
	_var_values = [data["first_var"]["value"], data["second_var"]["value"]]
	_operator_index = _operator_dropdown.selected
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

#endregion


## Set a value field based on the variable type
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

	# Connect the expand button to open the text editor
	if type == TYPE_STRING and field_data.field is HBoxContainer:
		var text_box = field_data.field.get_node("TextEdit")
		field_data.field.get_node("ExpandButton").pressed.connect(
				open_text_editor.emit.bind(text_box))
		text_box.focus_entered.connect(update_text_editor.emit.bind(text_box))


## Set the input field value
func _set_field_value(value: Variant, type: int, field_index: int) -> void:
	_var_values[field_index] = value
	SproutyDialogsVariableUtils.set_field_value(_value_inputs[field_index], type, value)


## Handle when a type is selected from the dropdown
func _on_type_selected(type_index: int, field_index: int) -> void:
	var temp_type = _type_indexes[field_index]
	var temp_value = _var_values[field_index]
	_set_value_field(type_index, field_index)
	modified.emit(true)

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Set Option Condition Type")
	undo_redo.add_do_method(self, "_set_value_field", type_index, field_index)
	undo_redo.add_do_property(_type_dropdowns[field_index], "selected", type_index)

	undo_redo.add_undo_method(self, "_set_value_field", temp_type, field_index)
	undo_redo.add_undo_property(_type_dropdowns[field_index], "selected", temp_type)
	undo_redo.add_undo_method(self, "_set_field_value", temp_value, temp_type, field_index)

	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	#-----------------------------------------------------------------------


## Handle when the operator is selected from the dropdown
func _on_operator_selected(index: int) -> void:
	if index != _operator_index:
		var temp = _operator_index
		_operator_index = index
		modified.emit(true)

		# --- UndoRedo -----------------------------------------------------
		undo_redo.create_action("Set Option Condition Operator")
		undo_redo.add_do_property(_operator_dropdown, "selected", index)
		undo_redo.add_undo_property(_operator_dropdown, "selected", temp)
		undo_redo.add_do_method(self, "emit_signal", "modified", true)
		undo_redo.add_undo_method(self, "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# ------------------------------------------------------------------


## Handle when the value changes in any of the value fields
func _on_value_changed(value: Variant, type: int, field: Control, field_index: int) -> void:
	if typeof(value) == typeof(_var_values[field_index]) and value == _var_values[field_index]:
		return # No value change
	
	var temp_value = _var_values[field_index]
	_var_values[field_index] = value
	_values_modified[field_index] = true

	# --- UndoRedo ---------------------------------------------------------
	undo_redo.create_action("Set Option Condition Value", 1)
	undo_redo.add_do_method(self, "_set_field_value", value, type, field_index)
	undo_redo.add_undo_method(self, "_set_field_value", temp_value, type, field_index)
	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ------------------------------------------------------------------


## Handle when a value input field loses focus
func _on_value_input_modified(field_index: int) -> void:
	if _values_modified[field_index]:
		_values_modified[field_index] = false
		modified.emit(true)


## Handle when the visibility option is changed in the dropdown
func _on_visibility_changed(index: int) -> void:
	if index != _visibility_index:
		var temp = _visibility_index
		_visibility_index = index
		modified.emit(true)

		# --- UndoRedo -----------------------------------------------------
		undo_redo.create_action("Set Option Condition Visibility")
		undo_redo.add_do_property(_visibility_dropdown, "selected", index)
		undo_redo.add_undo_property(_visibility_dropdown, "selected", temp)
		undo_redo.add_do_method(self, "emit_signal", "modified", true)
		undo_redo.add_undo_method(self, "emit_signal", "modified", false)
		undo_redo.commit_action(false)
		# ------------------------------------------------------------------


## Handle when the enable/disable check box is toggled
func _on_enable_condition_toggled(toggled_on: bool) -> void:
	var temp = _condition_enabled
	_condition_enabled = toggled_on
	modified.emit(true)

	# --- UndoRedo -----------------------------------------------------
	undo_redo.create_action("Enable/Disable Option Condition")
	undo_redo.add_do_method(_check_box, "set_pressed_no_signal", toggled_on)
	undo_redo.add_undo_method(_check_box, "set_pressed_no_signal", temp)
	undo_redo.add_do_method(self, "emit_signal", "modified", true)
	undo_redo.add_undo_method(self, "emit_signal", "modified", false)
	undo_redo.commit_action(false)
	# ------------------------------------------------------------------


## Show or collapse the condition section
func _on_expand_button_toggled(toggled_on: bool) -> void:
	if _conditions_box.get_parent() != self:
		_conditions_box.get_parent().visible = toggled_on

	_conditions_box.visible = toggled_on
	$Header/ExpandButton.icon = collapse_up_icon if toggled_on else collapse_down_icon

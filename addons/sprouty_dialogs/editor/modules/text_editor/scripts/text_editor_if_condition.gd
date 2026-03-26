@tool
extends HFlowContainer

# -----------------------------------------------------------------------------
# Text Editor If Condition
# -----------------------------------------------------------------------------
## Controller to add the If condition tag to the text in the text editor.
# -----------------------------------------------------------------------------

## Text editor reference
@export var text_editor: EditorSproutyDialogsTextEditor
## Operator dropdown field
@onready var _operator_dropdown: OptionButton = $OperatorDropdown
## Variable value input field
@onready var _value_field: PanelContainer = $ValueField

var _variable_name_input: EditorSproutyDialogsComboBox = null
var _value_type_dropdown: OptionButton = null
var _value_type_index: int = 0
var _value: Variant = null


func _ready() -> void:
	# Add the variable name input field with search option
	_variable_name_input = SproutyDialogsVariableUtils.new_field_by_type(40).field
	_variable_name_input.text_changed.connect(_on_variable_name_text_changed)
	_variable_name_input.placeholder_text = "Enter a variable name..."
	$VariableField.add_child(_variable_name_input)

	# Add the value type dropdown
	_value_type_dropdown = SproutyDialogsVariableUtils.get_types_dropdown(false,
			["Nil", "Variable", "Vector2", "Vector3", "Vector4",
			"Color", "Expression", "Dictionary", "Array", "File Path", "Dir Path"] # Excluded from options
		)
	_value_type_dropdown.item_selected.connect(_on_value_type_selected)
	$ValueTypeField.add_child(_value_type_dropdown)
	_value_type_dropdown.flat = true

	_operator_dropdown.item_selected.connect(_on_operator_selected)
	_operator_dropdown.flat = true
	
	var default_value_type_index: int = TYPE_STRING - 1
	_value_type_dropdown.set_item_metadata( # Remove expandable text box from string field
			default_value_type_index, {"hint": PROPERTY_HINT_NONE})
	_value_type_dropdown.selected = default_value_type_index
	_set_value_field(default_value_type_index)


## Update the value field by type
func _set_value_field(type_index: int) -> void:
	var type: int = _value_type_dropdown.get_item_id(type_index)
	var metadata = _value_type_dropdown.get_item_metadata(type_index)
	metadata = metadata if metadata else {}

	var field_data: Dictionary = SproutyDialogsVariableUtils.new_field_by_type(
		type, null, metadata, _on_value_changed
	)
	if _value_field.get_child_count() > 0:
		_value_field.remove_child(_value_field.get_child(0))
	_value_field.add_child(field_data.field)
	_value_type_index = type_index


## Update the value type field
func _on_value_type_selected(index: int) -> void:
	_set_value_field(index)


## Update variable name in the tag
func _on_variable_name_text_changed(_text: String) -> void:
	_insert_tag()


## Update the operator in the tag
func _on_operator_selected(_index: int) -> void:
	_insert_tag()


## Update the value in the tag
func _on_value_changed(value: Variant, _type: int, _field: Control) -> void:
	if typeof(value) == typeof(_value) and value == _value:
		return # No change in value, do nothing
	_value = value
	_insert_tag()


## Insert the updated tag
func _insert_tag() -> void:
	if not text_editor:
		return
	# Get selected variable name
	var var_name: String = _variable_name_input.get_value()
	# Get operator symbol text
	var op_symbol: String = _operator_dropdown.get_item_text(_operator_dropdown.selected)
	var op_token: String = _map_operator_symbol(op_symbol)
	# Basic escaping for double quotes inside attribute values
	var safe_var: String = var_name.replace('"', '\\"')
	var safe_value: String = str(_value) if _value != null else ""
	# Build open and close tag using safe tokens for operator
	var open_tag: String = "[if var=" + safe_var + " op=" + op_token + " val=" + safe_value + "]"
	var close_tag: String = "[/if]"

	text_editor.update_code_tags(open_tag, close_tag, "", true)


# Map operator symbol to a safe token
func _map_operator_symbol(op_symbol: String) -> String:
	match op_symbol:
		"==": return "eq"
		"!=": return "ne"
		"<": return "lt"
		">": return "gt"
		"<=": return "le"
		">=": return "ge"
		_: return op_symbol.replace(" ", "_")

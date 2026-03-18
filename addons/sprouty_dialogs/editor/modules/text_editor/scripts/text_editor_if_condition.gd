@tool
extends HFlowContainer


## Text editor reference
@export var text_editor: EditorSproutyDialogsTextEditor
## Variable name dropdown field
@onready var _variable_name_input: EditorSproutyDialogsComboBox = $VariableNameInput
## Operator dropdown field
@onready var _operator_dropdown: OptionButton = $OperatorDropdown
## Variable value input field
@onready var _value_field: PanelContainer = $ValueField

var _value_type_dropdown: OptionButton = null
var _value_type_index: int = 0
var _value: Variant = null


func _ready() -> void:
	$VariableTypeField.add_child(
		SproutyDialogsVariableUtils.get_types_dropdown(false,
			["Nil", "bool", "int", "float", "String", "Vector2", "Vector3", "Vector4",
			"Color","Expression", "Dictionary", "Array", "File Path", "Dir Path"] # Excluded from options
		))
	$ValueTypeField.add_child(
		SproutyDialogsVariableUtils.get_types_dropdown(false,
			["Nil", "Variable", "Vector2", "Vector3", "Vector4",
			"Color","Expression", "Dictionary", "Array", "File Path", "Dir Path"] # Excluded from options
		))
	
	_value_type_dropdown = $ValueTypeField.get_child(0)
	_value_type_dropdown.flat = true
	_value_type_dropdown.item_selected.connect(_on_value_type_selected)
	_variable_name_input.text_changed.connect(_on_variable_name_text_changed)
	_operator_dropdown.flat = true
	_operator_dropdown.item_selected.connect(_on_operator_selected)
	
	var default_value_type_index: int = 3
	_value_type_dropdown.selected = default_value_type_index
	_set_value_field(default_value_type_index)
	

func _set_value_field(type_index: int) -> void:
	var type: int = _value_type_dropdown.get_item_id(type_index)
	var field_data: Dictionary = SproutyDialogsVariableUtils.new_field_by_type(
		type, null, {}, _on_value_changed
	)
	if _value_field.get_child_count() > 0:
		_value_field.remove_child(_value_field.get_child(0))
	_value_field.add_child(field_data.field)
	_value_type_index = type_index


func _on_value_type_selected(index: int) -> void:
	_set_value_field(index)


func _on_variable_name_text_changed(_text: String) -> void:
	_insert_tag()


func _on_operator_selected(_index: int) -> void:
	_insert_tag()


func _on_value_changed(value: Variant, _type: int, _field: Control) -> void:
	if typeof(value) == typeof(_value) and value == _value:
		return # No change in value, do nothing
	_value = value
	_insert_tag()


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

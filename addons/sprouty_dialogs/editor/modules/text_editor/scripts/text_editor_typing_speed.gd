@tool
extends HFlowContainer

## Text editor reference
@export var text_editor: EditorSproutyDialogsTextEditor
@onready var _type_dropdown: OptionButton = $TypeDropdown
@onready var _value_input: SpinBox = $ValueInput

var _value: float = 0.0


func _ready() -> void:
	$TypeDropdown.item_selected.connect(_on_type_selected)
	$ValueInput.value_changed.connect(_on_input_value_changed)


func _on_type_selected(index: int) -> void:
	var type_id: int = _type_dropdown.get_item_id(index)
	match type_id:
		0: # Absolute Speed
			_value_input.suffix = "s"
			_value_input.step = 0.001
			_value_input.value = 0.0
		1: # Relative Speed
			_value_input.suffix = "x"
			_value_input.step = 0.01
			_value_input.value = 1.0
		2: # Wait
			_value_input.suffix = "s"
			_value_input.step = 0.001
			_value_input.value = 0.0


func _on_input_value_changed(value: float) -> void:
	_value = value
	_insert_tag()


func _insert_tag() -> void:
	if not text_editor:
		return
	match _type_dropdown.selected:
		0: # Absolute Speed
			text_editor.update_code_tags("[speed=" + str(_value) + "]", "[/speed]", "", true)
		1: # Relative Speed
			text_editor.update_code_tags("[speed=" + str(_value) + "x]", "[/speed]", "", true)
		2: # Wait
			text_editor.update_code_tags("[wait=" + str(_value) + "]", "", "", true)
	

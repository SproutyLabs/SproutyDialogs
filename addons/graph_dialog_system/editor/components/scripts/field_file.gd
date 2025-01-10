@tool
extends MarginContainer

@export var file_filters : PackedStringArray

var current_value : String
var file_dialog : FileDialog

# Called when the node enters the scene tree for the first time.
func _ready():
	file_dialog = find_parent("Main").get_node("OpenFileDialog")
	file_dialog.connect("file_selected", _on_file_dialog_selected)
	
	%OpenButton.button_down.connect(_on_open_pressed)
	%ClearButton.button_up.connect(clear_path)

func _set_value(value:Variant) -> void:
	current_value = value
	%Field.text = value

func _on_open_pressed() -> void:
	file_dialog.filters = file_filters
	file_dialog.visible = true

func _on_file_dialog_selected(path : String) -> void:
	_set_value(path)

func clear_path() -> void:
	_set_value("")

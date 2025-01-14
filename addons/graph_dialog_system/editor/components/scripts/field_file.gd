@tool
extends MarginContainer

signal file_path_changed(path : String)

@export var file_filters : PackedStringArray

@onready var file_dialog : FileDialog = $OpenFileDialog
var current_value : String

func _ready():
	file_dialog.connect("file_selected", _on_file_dialog_selected)
	
	%OpenButton.button_down.connect(_on_open_pressed)
	%ClearButton.button_up.connect(clear_path)

func set_value(value : String) -> void:
	current_value = value
	%Field.text = value

func _on_open_pressed() -> void:
	file_dialog.filters = file_filters
	file_dialog.visible = true

func _on_file_dialog_selected(path : String) -> void:
	file_path_changed.emit(path)
	set_value(path)

func clear_path() -> void:
	set_value("")

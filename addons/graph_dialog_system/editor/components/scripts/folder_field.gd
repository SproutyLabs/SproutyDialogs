@tool
extends MarginContainer

signal path_changed(path : String)

@onready var folder_dialog : FileDialog = $OpenFileDialog
var current_value : String

func _ready():
	folder_dialog.connect("file_selected", _on_folder_path_selected)
	
	%OpenButton.button_down.connect(_on_open_pressed)
	%ClearButton.button_up.connect(clear_path)

func set_value(value : String) -> void:
	current_value = value
	%Field.text = value

func _on_open_pressed() -> void:
	folder_dialog.popup_centered()

func _on_folder_path_selected(path : String) -> void:
	file_path_changed.emit(path)
	set_value(path)

func clear_path() -> void:
	set_value("")

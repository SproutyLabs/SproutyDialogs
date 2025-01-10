@tool
class_name OptionContainer
extends VBoxContainer

signal option_removed(index)

@onready var option_label = $OptionHeader/OptionLabel

var option_index : int = 0
var dialog_key : String = ""

func _ready() -> void:
	_show_remove_button()

func update_option_index(index : int) -> void:
	# Update the option position index
	option_label.text = "Option #" + str(index + 1)
	name = name.split('_')[0] + "_" + str(index)
	option_index = index
	_show_remove_button()

func _show_remove_button() -> void:
	# Show remove button when it is not the first option
	$OptionHeader/RemoveButton.visible = option_index

func _on_remove_button_pressed() -> void:
	# Delete the option
	option_removed.emit(option_index)

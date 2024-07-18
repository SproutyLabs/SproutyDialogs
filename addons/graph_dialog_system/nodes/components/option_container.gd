@tool
extends VBoxContainer

signal option_removed(index)

@onready var option_label = $OptionHeader/OptionLabel

var option_index : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_option_index(index : int) -> void:
	# Update the option position index
	option_label.text = "Option #" + str(index + 1)
	name = name.split('_')[0] + "_" + str(index)
	option_index = index

func _on_remove_button_pressed() -> void:
	# Delete the option
	option_removed.emit(option_index)

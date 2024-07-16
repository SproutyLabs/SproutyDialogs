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

func update_option_number(number : int):
	# Update the option position number
	option_label.text = "Option #" + str(number + 1)
	option_index = number

func _on_remove_button_pressed():
	# Delete the option
	option_removed.emit(option_index)
	queue_free()

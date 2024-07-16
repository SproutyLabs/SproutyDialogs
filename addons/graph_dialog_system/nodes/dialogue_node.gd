@tool
extends GraphNode

@onready var choices_label : Label = $ChoicesContainer/ChoicesLabel
@onready var choices_toggle : CheckButton = $ChoicesContainer/ChoicesToggle

func _ready():
	choices_toggle.button_pressed = false
	_show_choices_port(false)
	pass # Replace with function body.

func _show_choices_port(isActive : bool):
	# Show or hide the port to connect a choices node
	choices_label.visible = isActive
	set_slot(3, false, 0, Color.WHITE, isActive, 0, Color.WHITE)

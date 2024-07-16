@tool
extends VBoxContainer

@onready var text_boxes = $TextBoxes

func _ready():
	text_boxes.visible = false

func _on_expand_button_toggled(toggled_on : bool):
	text_boxes.visible = toggled_on

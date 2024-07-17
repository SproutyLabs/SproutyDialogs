@tool
extends HBoxContainer

@onready var dialogue_input = $DialogueInput
@onready var expanded_panel = $ExpandedTextPanel
@onready var expanded_text_input = $ExpandedTextPanel/VBoxContainer/ExpandedInput

func _on_expand_button_pressed():
	# Open the extended window to edit text
	expanded_text_input.text = dialogue_input.text
	expanded_panel.popup_centered()
	expanded_text_input.grab_focus()

func _on_expanded_close_button_pressed():
	dialogue_input.text = expanded_text_input.text
	expanded_panel.hide() # Close the extended window

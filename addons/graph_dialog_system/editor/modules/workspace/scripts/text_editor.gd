@tool
extends Panel

## =============================================================================
## Text editor
##
## This script handles a text editor window.
## =============================================================================

## Input text box
@onready var text_box: CodeEdit = %CodeEdit

var edited_text_box: TextEdit

func _ready():
	visible = false

## Show the text editor
func show_text_editor() -> void:
	text_box.text = edited_text_box.text
	visible = true

## Hide the text editor
func hide_text_editor() -> void:
	visible = false

func _on_close_button_pressed():
	hide_text_editor()

func _on_code_edit_text_changed():
	edited_text_box.text = text_box.text

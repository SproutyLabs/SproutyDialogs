@tool
class_name GraphDialogsOptionContainer
extends VBoxContainer

## -----------------------------------------------------------------------------
## Option container component
##
## Component that display a dialog option in the options node.
## -----------------------------------------------------------------------------

## Triggered when the option is removed
signal option_removed(index)

## Option header to display the option position index
@onready var _option_label = $OptionHeader/OptionLabel
## Remove button
@onready var _remove_button = $OptionHeader/RemoveButton

## Option position index
var option_index: int = 0
## Dialog translation key of the option
var dialog_key: String = ""


func _ready() -> void:
	_remove_button.icon = get_theme_icon("Remove", "EditorIcons")
	_show_remove_button()


## Update the option position index
func update_option_index(index: int) -> void:
	_option_label.text = "Option #" + str(index + 1)
	name = name.split('_')[0] + "_" + str(index)
	option_index = index
	_show_remove_button()


## Show remove button only when it is not the first option
func _show_remove_button() -> void:
	$OptionHeader/RemoveButton.visible = option_index


## Remove option when the remove button is pressed
func _on_remove_button_pressed() -> void:
	option_removed.emit(option_index)

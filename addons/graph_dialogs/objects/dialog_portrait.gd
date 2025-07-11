@tool
class_name DialogPortrait
extends Node

# -----------------------------------------------------------------------------
## Dialog Portrait base class
##
## This class is used to handle the behavior of a portrait for a character.
## It is an abstract class that should be inherited by the portrait controllers.
# -----------------------------------------------------------------------------


## Abstract method to override.
## Set the default behavior of the portrait.
## This is called when the portrait is instantiated or changed.
func set_portrait() -> void:
	pass


## Abstract method to override.
## Update the portrait when character joins the scene.
## This is called when the character is added to the scene.
func on_portrait_entry() -> void:
	pass


## Abstract method to override.
## Update the portrait when character leaves the scene.
## This is called when the character is removed from the scene.
func on_portrait_exit() -> void:
	pass


## Abstract method to override.
## Update the portrait when the character is talking.
## This is called when the typing of the dialog starts.
func on_portrait_talk() -> void:
	pass


## Abstract method to override.
## Update the portrait when the character stops talking.
## This is called when the typing of the dialog is finished.
func on_portrait_stop_talking() -> void:
	pass


## Abstract method to override.
## Update the portrait when the character is active in the dialog,
## but is not currently talking (e.g. waiting for user input, joins without dialog).
## This is called when the character is active but not currently talking.
func highlight_portrait() -> void:
	pass


## Abstract method to override.
## Update the portrait when the character is not active in the dialog,
## (e.g. when the speaker is changed to another character).
## This is called when the character becomes inactive in the dialog.
func unhighlight_portrait() -> void:
	pass

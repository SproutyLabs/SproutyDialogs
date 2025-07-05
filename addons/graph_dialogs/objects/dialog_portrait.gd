@tool
class_name DialogPortrait
extends Node

## -----------------------------------------------------------------------------
## Portrait base class
##
## This class is used to handle the behavior of a portrait for a character.
## It is an abstract class that should be inherited by the portrait controllers.
## -----------------------------------------------------------------------------


## Abstract method to override.
## Default behavior of the portrait.
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
## Update the portrait when the character is the active speaker in the dialog,
## but is not currently talking (e.g. waiting for user input).
## This is called when the character ends talking, but is still the active speaker
## in the dialog, and for other situations where the character is highlighted
## but not actively talking.
func on_portrait_highlight() -> void:
	pass


## Abstract method to override.
## Update the portrait when the character is not the active speaker in the dialog.
## This is called when the speaker is changed for other character.
func on_portrait_unhighlight() -> void:
	pass

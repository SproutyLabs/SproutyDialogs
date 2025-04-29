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
## Default behavior of the portrait when is active.
## This is called when the portrait is instantiated or changed.
func update_portrait() -> void:
	pass


## Abstract method to override.
## Update the portrait when character joins the scene.
## This is called when the character enters the scene.
## Then the portrait goes to its default behavior (update_portrait is called)
func on_portrait_entry() -> void:
	pass


## Abstract method to override.
## Update the portrait when character leaves the scene.
## This is called when the character is removed from the scene.
func on_portrait_exit() -> void:
	pass


## Abstract method to override.
## Update the portrait when the character is talking.
## This is called when the dialog is being typed.
func on_portrait_talk() -> void:
	pass


## Abstract method to override.
## Update the portrait when the character stops talking.
## This is called when the dialog is finished.
## Then the portrait goes to its default behavior (update_portrait is called)
func on_portrait_talk_end() -> void:
	pass

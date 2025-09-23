@tool
@icon("res://addons/sprouty_dialogs/icons/character.svg")
@abstract
class_name DialogPortrait
extends Node

# -----------------------------------------------------------------------------
# Sprouty Dialogs Dialog Portrait
# -----------------------------------------------------------------------------
## This class is used to handle the behavior of a portrait for a character.
## 
## It is an abstract class that should be inherited by other classes to define
## specific portrait behaviors.
# -----------------------------------------------------------------------------


## Set the default behavior of the portrait.
## This is called when the portrait is instantiated or changed.
@abstract func set_portrait()


## Update the portrait when character joins the scene.
## This is called when the character is added to the scene.
@abstract func on_portrait_entry()


## Update the portrait when character leaves the scene.
## This is called when the character is removed from the scene.
@abstract func on_portrait_exit()


## Update the portrait when the character is talking.
## This is called when the typing of the dialog starts.
@abstract func on_portrait_talk()


## Update the portrait when the character stops talking.
## This is called when the typing of the dialog is finished.
@abstract func on_portrait_stop_talking()


## Update the portrait when the character is active in the dialog,
## but is not currently talking (e.g. waiting for user input, joins without dialog).
## This is called when the character is active but not currently talking.
@abstract func highlight_portrait()


## Update the portrait when the character is not active in the dialog,
## (e.g. when the speaker is changed to another character).
## This is called when the character becomes inactive in the dialog.
@abstract func unhighlight_portrait()

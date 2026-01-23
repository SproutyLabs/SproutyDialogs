@tool
@icon("res://addons/sprouty_dialogs/editor/icons/character.svg")
@abstract
class_name DialogPortrait
extends Node

# -----------------------------------------------------------------------------
# Sprouty Dialogs Dialog Portrait
# -----------------------------------------------------------------------------
## Abstract class for dialog portraits from Sprouty Dialogs plugin.
## 
## It provides the basic methods to handle the portrait behavior during a dialog.
##
## [br][br]You should inherit from this class to create your own dialog portraits.
# -----------------------------------------------------------------------------


## Override this method to set up the portrait initially.
## This is called when the portrait is instantiated or changed.
@abstract func set_portrait() -> void


## Override this method to update the portrait when character enters the scene.
## This is called when the character is added to the scene.
@abstract func on_portrait_enter() -> void


## Override this method to update the portrait when character exits the scene.
## This is called when the character is removed from the scene.
@abstract func on_portrait_exit() -> void


## Override this method to update the portrait when the character starts talking.
## This is called when the typing of the dialog starts.
@abstract func on_portrait_talk() -> void


## Override this method to update the portrait when the character stops talking.
## This is called when the typing of the dialog is finished.
@abstract func on_portrait_stop_talking() -> void


## Override this method to update the portrait when the character is active in the dialog,
## but is not currently talking (e.g. waiting for user input, joins without dialog).
## This is called when the character is active but not currently talking.
@abstract func highlight_portrait() -> void


## Override this method to update the portrait when the character becomes 
## inactive in the dialog (e.g. when the speaker is changed to another character).
## This is called when the character becomes inactive in the dialog.
@abstract func unhighlight_portrait() -> void

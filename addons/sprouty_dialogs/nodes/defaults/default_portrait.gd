@tool
extends DialogPortrait

# -----------------------------------------------------------------------------
# This is a template for a dialog portrait with a default behavior.
# -----------------------------------------------------------------------------
## This script provides a basic implementation of a dialog portrait behavior.
## You can override the properties and methods to implement your own logic.
##
## About properties:
## The exported properties (@export annotation) will be shown in the editor.
## that allows to use the same script and scene for different characters,
## you only need to change the properties in the portrait editor for each case.
##
## If you want to hide some properties from the editor, put them in a group
## called "Private" (@export_group("Private")).
##
## -- NOTE ------------------------------------------------------------
## You can delete everything you don't need from this template, except 
## the DialogPortrait methods because are needed to use the portraits.
## --------------------------------------------------------------------
# -----------------------------------------------------------------------------

## Portrait image file path
@export_file("*.png", "*.jpg", "*.svg") var portrait_image: String

@export_group("Private")
## Animation time for default portrait animations
@export var animation_time: float = 1.0

## Tween for animations 
var _tween: Tween = null


func set_portrait() -> void:
	# -------------------------------------------------------------------
	# This method is called when the portrait is instantiated or changed.
	# This is the default behavior of the portrait.
	# You can add your own logic here to handle the portrait.
	# -------------------------------------------------------------------
	# In this base case, a portrait image is loaded and set it to the sprite
	if portrait_image != "" and ResourceLoader.exists(portrait_image):
		$Sprite2D.texture = load(portrait_image)


func on_portrait_enter() -> void:
	# --------------------------------------------------------------------------
	# This method is called when the character joins the scene.
	# You can add your own logic here to handle when the character enters.
	# --------------------------------------------------------------------------
	# In this base case, the portrait is animated to enter the scene with fade in
	_fade_in_animation($Sprite2D)
	await _tween.finished # Wait for the animation to finish


func on_portrait_exit() -> void:
	# --------------------------------------------------------------------------
	# This method is called when the character leaves the scene.
	# You can add your own logic here to handle when the character leaves.
	# --------------------------------------------------------------------------
	# In this base case, the portrait is animated to exit the scene with fade out
	_fade_out_animation($Sprite2D)
	await _tween.finished # Wait for the animation to finish


func on_portrait_talk() -> void:
	# --------------------------------------------------------------------------
	# This method is called when the character starts talking (typing starts).
	# You can add your own logic here to handle when the character talks
	# --------------------------------------------------------------------------
	# In this base case, the portrait is animated to talk with a custom animation
	_talking_animation($Sprite2D)


func on_portrait_stop_talking() -> void:
	# --------------------------------------------------------------------------
	# This method is called when the character stops talking (typing ends).
	# You can add your own logic here to handle when the character stops talking
	# --------------------------------------------------------------------------
	_tween.stop() # Stop the talking animation
	highlight_portrait() # Reset the state when the character stops talking


func highlight_portrait() -> void:
	# --------------------------------------------------------------------------
	# This method is called when the character is active in the dialog,
	# but is not currently talking (e.g. waiting for user input).
	# You can add your own logic here to handle when the character is highlighted.
	# --------------------------------------------------------------------------
	# In this base case, the portrait is highlighted by unsetting transparency
	$Sprite2D.modulate.a = 1.0


func unhighlight_portrait() -> void:
	# --------------------------------------------------------------------------
	# This method is called when the character is not active in the dialog.
	# (e.g. when the speaker is changed to another character).
	# You can add your own logic here to handle when the character is not highlighted.
	# --------------------------------------------------------------------------
	# In this base case, the portrait is unhighlighted by adding semi-transparency
	$Sprite2D.modulate.a = 0.5


#region === Placeholder Animations =============================================

## Fade in animation.
## It animates the portrait to enter the scene with a fade in effect.
## (You can delete this method if you don't need it)
func _fade_in_animation(node: Node) -> void:
	var end_position = node.position.y
	node.position.y += node.get_viewport().size.y / 5
	node.modulate.a = 0.0

	_tween = self.create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_parallel()
	_tween.tween_property(node, "position:y", end_position, animation_time)
	_tween.tween_property(node, "modulate:a", 1.0, animation_time)


## Fade out animation.
## It animates the portrait to exit the scene with a fade out effect.
## (You can delete this method if you don't need it)
func _fade_out_animation(node: Node) -> void:
	var end_position = node.position.y + node.get_viewport().size.y / 5
	_tween = self.create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_parallel()
	_tween.tween_property(node, "position:y", end_position, animation_time)
	_tween.tween_property(node, "modulate:a", 0.0, animation_time)


## Talking animation.
## It animates the portrait while the character is talking.
## (You can delete this method if you don't need it)
func _talking_animation(node: Node) -> void:
	_tween = self.create_tween().set_loops()
	_tween.tween_property(node, 'scale:y', node.scale.y * 1.05, 0.1)
	_tween.tween_property(node, 'scale:y', node.scale.y, 0.1)

#endregion

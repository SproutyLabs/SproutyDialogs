@tool
extends DialogPortrait

## -----------------------------------------------------------------------------
## This is a template for a dialog portrait with a default behavior.
##
## This script provides a basic implementation of a dialog portrait behavior.
## You can override the properties and methods to implement your own logic.
##
## About properties:
## The exported properties (@export annotation) will be shown in the editor.
## that allows to use the same script and scene for different characters,
## you only need to change the properties in the portrait editor for each case.
##
## If you want to hide some properties from the editor, put them in a group
## called "private" (@export_group("private")).
## -----------------------------------------------------------------------------

## Portrait image file path
@export_file("*.png", "*.jpg") var portrait_image: String

@export_group("private")
@export var animation_time: float = 1.0


func update_portrait() -> void:
	# -------------------------------------------------------------------
	# This method is called when the portrait is instantiated or changed.
	# This is the default behavior of the portrait when is active.
	# You can add your own logic here to handle the portrait update.
	# -------------------------------------------------------------------
	# In this base case, a portrait image is loaded and set it to the sprite
	if portrait_image != "" and FileAccess.file_exists(portrait_image):
		$Sprite2D.texture = load(portrait_image)


func on_portrait_entry() -> void:
	# -------------------------------------------------------------------
	# This method is called when the character enters the scene.
	# Then the portrait goes to its default behavior (update_portrait is called).
	# You can add your own logic here to handle the portrait when the character enters.
	# -------------------------------------------------------------------
	# In this base case, the portrait is animated to enter the scene with fade in
	_fade_in_animation($Sprite2D)


func on_portrait_exit() -> void:
	# -------------------------------------------------------------------
	# This method is called when the character leaves the scene
	# You can add your own logic here to handle the portrait when the character leaves
	# -------------------------------------------------------------------
	# In this base case, the portrait is animated to exit the scene with fade out
	_fade_out_animation($Sprite2D)


func on_portrait_talk() -> void:
	# --------------------------------------------------------------------
	# This method is called when the character starts talking (typing dialog)
	# You can add your own logic here to handle the portrait when the character talks
	# --------------------------------------------------------------------
	# In this base case, the portrait is animated to talk with a custom animation
	_bounce_animation($Sprite2D)


func on_portrait_talk_end() -> void:
	# --------------------------------------------------------------------
	# This method is called when the character stops talking (dialog finished)
	# Then the portrait goes to its default behavior (update_portrait is called)
	# You can add your own logic here to handle the portrait when the character stops talking
	# --------------------------------------------------------------------
	get_node("bounce_animation").kill()


## Fade in animation.
## It animates the portrait to enter the scene with a fade in effect.
## You can delete this method if you don't want to use it.
func _fade_in_animation(node: Node) -> void:
	var end_position = node.position
	node.position.y += node.get_viewport().size.y / 5
	node.modulate = Color.TRANSPARENT

	var tween := self.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_parallel()
	tween.tween_property(node, "position", end_position, animation_time)
	tween.tween_property(node, "modulation:a", 1.0, animation_time)


## Fade out animation.
## It animates the portrait to exit the scene with a fade out effect.
## You can delete this method if you don't want to use it.
func _fade_out_animation(node: Node) -> void:
	var end_position = node.position.y + node.get_viewport().size.y / 5
	var tween := self.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_parallel()
	tween.tween_property(node, "position", end_position, animation_time)
	tween.tween_property(node, "modulation:a", 0.0, animation_time)


## Bounce animation.
## It animates the portrait to bounce when the character is talking.
## You can delete this method if you don't want to use it.
func _bounce_animation(node: Node) -> void:
	var tween := self.create_tween().set_loops()
	tween.name = "bounce_animation"
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		node,
		'position:y',
		node.position.y - node.get_viewport().size.y / 10,
		animation_time * 0.4
		).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property(
		node, 'scale:y',
		node.scale.y * 1.05,
		animation_time * 0.4
		).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(
		node,
		'position:y',
		node.position.y,
		animation_time * 0.6
		).set_trans(Tween.TRANS_BOUNCE)
	tween.parallel().tween_property(
		node,
		'scale:y',
		node.scale.y,
		animation_time * 0.6
		).set_trans(Tween.TRANS_BOUNCE)
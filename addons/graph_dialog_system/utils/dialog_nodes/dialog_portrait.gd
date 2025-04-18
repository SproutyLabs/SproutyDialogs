@tool
class_name DialogPortrait
extends Node

@export var _portrait_image: Texture2D
@export var _portrait_display: Sprite2D


## Set the portrait image to be displayed in the sprite 2D node
func set_portrait_image(portrait: Texture2D) -> void:
	_portrait_image = portrait
	_portrait_display.texture = _portrait_image
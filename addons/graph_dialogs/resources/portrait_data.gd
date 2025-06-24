@tool
class_name GraphDialogsPortraitData
extends Resource

## -----------------------------------------------------------------------------
## Portrait Data Resource
##
## This resource is used to store portrait data of a character.
## -----------------------------------------------------------------------------

## Portrait scene path.
## This is the UID of the scene that will be used as the character's portrait.
## The scene should contain a root node that extends [class DialogPortrait]
## to can integrate with the dialog system.
@export var portrait_scene: int = -1
## Portrait exported overrides properties.
## This is a dictionary where each key is the property name to override
## and its value is the new value for that property.
@export var export_overrides: Dictionary = {}
## Transform settings for the portrait.
## This is a dictionary containing the following keys:
##  - "scale": the scale of the portrait.
##  - "scale_lock_ratio": whether to lock the aspect ratio of the scale.
##  - "offset": the offset of the portrait.
##  - "rotation": the rotation of the portrait in degrees.
##  - "mirror": whether to mirror the portrait.
@export var transform_settings: Dictionary = {
	"scale": Vector2.ZERO,
	"scale_lock_ratio": false,
	"offset": Vector2.ZERO,
	"rotation": 0.0,
	"mirror": false
}
## Typing sound for the character portrait.
## This is a dictionary containing the sound data for typing sounds.
@export var typing_sound: Dictionary = {
	"path": "",
	"volume": 1.0,
	"pitch": 1.0
}
@tool
class_name SproutyDialogsPortraitData
extends Resource

# -----------------------------------------------------------------------------
# Sprouty Dialogs Portrait Data
# -----------------------------------------------------------------------------
## This resource stores data for character portraits.
##
## Each portrait includes the reference for the portrait scene, transform 
## settings, overrides properties, and optionally a typing sound.
# -----------------------------------------------------------------------------

## Reference to the portrait scene used for this portrait.
## This is the UID of the scene that will be used as the character's portrait.
## The scene should contain a root node that extends [class DialogPortrait]
## to can integrate with the dialog system.
@export var portrait_scene_uid: int = -1
## Path to the portrait scene used for this portrait.
## This is for reference only, use [param portrait_scene_uid] to set the portrait scene
@export var portrait_scene_path: String = ""
## Portrait exported overrides properties.
## This is a dictionary where each key is the property name to override
## and its value is a dictionary containing the value and type of the property.
## The dictionary structure is as follows:
## [codeblock]{
##   "property_name_1": {
##     "value": value_of_property_1,
##     "type": 0  (from Variant.Type enum. e.g., 0 for NIL)
##   },
##   "property_name_2": {
##     "value": value_of_property_2,
##     "type": 1 (from Variant.Type enum. e.g., 1 for BOOL)
##   },
##   ...
## }[/codeblock]
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
} # (Not used yet, typing sounds implementation is pending)!
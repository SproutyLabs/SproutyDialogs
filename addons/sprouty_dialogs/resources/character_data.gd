@tool
class_name SproutyDialogsCharacterData
extends Resource

# -----------------------------------------------------------------------------
# Sprouty Dialogs Character Data
# ----------------------------------------------------------------------------- 
## This resource stores data for a character in the dialogue system.
##
## It includes the character's key name or identifier, translations of the name,
## description, dialog box reference, portraits and typing sounds.
# -----------------------------------------------------------------------------

## Character identifier.
## Corresponds to the file name of the character's resource.
@export var key_name: String = ""
## Name of the character that will be displayed in the dialogue.
## The display name can be localized to different languages, so it is stored
## as a dictionary where each key is a locale code (e.g., "en", "fr")
## and its value is the name translated in that locale. 
## Example: [codeblock]
## {
##   "en": "Name in English"
##   "es": "Nombre en Español"
##   ...
## }[/codeblock]
@export var display_name: Dictionary = {}
## Character description.
## This does nothing, its only for your reference.
@export var description: String = ""
## Reference to the dialog box scene used by this character.
## This is the UID of a scene that contains a [class DialogBox] node
## which will be used to display the character's dialogue.
@export var dialog_box_uid: int = -1
## Path to the dialog box scene to display the character's dialogue.
## This is for reference only, use [param dialog_box_uid] to set the dialog box
@export var dialog_box_path: String = ""
## Flag to indicate if the character's portrait should be displayed on the dialog box.
## If true, the character's portrait scene will be shown in the [param display portrait]
## node of the [class DialogBox]. For this you need to set the [param display portrait]
## node that will hold the portrait as a parent of the portrait scene.
@export var portrait_on_dialog_box: bool = false
## Name of the default portrait to use for this character. 
## If set, this portrait will be used when no specific portrait is specified in the dialogue.
@export var default_portrait: String = ""
## Transform settings for all character portraits.
## This is a dictionary with the following keys:
##  - "scale": the scale of the portrait.
##  - "scale_lock_ratio": whether to lock the aspect ratio of the scale.
##  - "offset": the offset of the portrait.
##  - "rotation": the rotation of the portrait in degrees.
##  - "mirror": whether to mirror the portrait.
@export var main_transform_settings: Dictionary = {
	"scale": Vector2.ONE,
	"scale_lock_ratio": true,
	"offset": Vector2.ZERO,
	"rotation": 0.0,
	"mirror": false
}
## Character's portraits.
## This is a dictionary where each key is a portrait name or a group of portraits
## and its value is a dictionary containing the portrait data or more portraits.
## The dictionary structure is as follows:
## [codeblock]
## {
##   "portrait_name_1": {
##  	"index" : 0,
##  	"data": SproutyDialogsPortraitData (SubResource)
##   },
##   "portrait_group": {
##  	"index" : 1,
##      "data": {
##  		 "portrait_name_2": {
##  			"index" : 0,
##  			"data": SproutyDialogsPortraitData (SubResource)
##  		 },
##		    ...
##      },
##  	 ...
##   },
##   ...
## }[/codeblock]
@export var portraits: Dictionary = {}
## Typing sounds for the character.
## This is a dictionary where each key is the sound name (e.g., "typing_1")
## and its value is a dictionary containing the sound data.
## The dictionary structure is as follows:
## [codeblock]
## {
##   "sound_1": {
##     "path": "res://path/to/typing_1.wav",
##     "volume": 0.5,
##     "pitch": 1.0
##   },
##   "sound_2": {
##     "path": "res://path/to/typing_2.wav",
##     "volume": 0.5,
##     "pitch": 1.0
##   },
##   ...
## }[/codeblock]
## (Not used yet, typing sounds implementation is pending)!
@export var typing_sounds: Dictionary = {}


## Returns the portrait data for a given portrait path name.
## The path name can be a portrait name or a path (e.g., "group/portrait").
## If the portrait is a group, it will recursively search for the portrait data.
func get_portrait_from_path_name(path_name: String, group: Dictionary = {"data": portraits}) -> Variant:
	if group.data.has(path_name) and group.data[path_name].data is SproutyDialogsPortraitData:
		return group.data[path_name].data
	
	if path_name.contains("/"):
		var parts = path_name.split("/")
		if group.data.has(parts[0]):
			return get_portrait_from_path_name("/".join(parts.slice(1, parts.size())), group.data[parts[0]])
	return null
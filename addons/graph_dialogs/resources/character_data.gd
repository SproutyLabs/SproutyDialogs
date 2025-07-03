@tool
class_name GraphDialogsCharacterData
extends Resource

## -----------------------------------------------------------------------------
## Character Data Resource
## 
## This resource is used to store character data.
## -----------------------------------------------------------------------------

## Character identifier.
## Corresponds to the file name of the character's resource.
@export var key_name: String = ""
## Name of the character that will be displayed in the dialogue.
## This is a dictionary where each key is a locale code (e.g., "en", "fr")
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
## Dialog box to display the character's dialogue.
## This is the UID of a scene that contains a [class DialogBox] node.
@export var dialog_box: int = -1
## Flag to indicate if the character's portrait should be displayed on the dialog box.
## If true, the character's portrait scene will be shown in the [param display portrait]
## node of the [class DialogBox]. For this you need to set the [param display portrait]
## node that will hold the portrait as a parent of the portrait scene.
@export var portrait_on_dialog_box: bool = false
## Character's portraits.
## This is a dictionary where each key is a portrait name or a group of portraits
## and its value is a dictionary containing the portrait data or more portraits.
## The dictionary structure is as follows:
## [codeblock]
## {
##   "portrait_name_1": GraphDialogsPortraitData (SubResource)
##   "portrait_group": {
##  	 "portrait_name_2": GraphDialogsPortraitData (SubResource)
##  	 "portrait_name_3": GraphDialogsPortraitData (SubResource)
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
@export var typing_sounds: Dictionary = {}


## Returns the portrait data for a given portrait path name.
## The path name can be a portrait name or a path (e.g., "group/portrait").
## If the portrait is a group, it will recursively search for the portrait data.
func get_portrait_from_path_name(path_name: String, group: Dictionary = portraits) -> Variant:
	if group.has(path_name) and group[path_name] is GraphDialogsPortraitData:
		return group[path_name]
	
	if path_name.contains("/"):
		var parts = path_name.split("/")
		if group.has(parts[0]):
			return get_portrait_from_path_name("/".join(parts.slice(1, parts.size())), group[parts[0]])
	return null
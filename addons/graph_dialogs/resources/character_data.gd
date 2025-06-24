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
## Text box to display the character's dialogue.
## This is the UID of a scene that contains a [class DialogBox] node.
@export var text_box: int = -1
## Flag to indicate if the character's portrait should be displayed on the text box.
## If true, the character's portrait scene will be shown in the [param display portrait]
## node of the [class DialogBox]. For this you need to set the [param display portrait]
## node that will hold the portrait as a parent of the portrait scene.
@export var portrait_on_text_box: bool = false
## Character's portraits.
## This is a dictionary where each key is a portrait name or a group of portraits
## and its value is a dictionary containing the portrait data or more portraits.
## The dictionary structure is as follows:
## [codeblock]
## {
##   "portrait_1": GraphDialogsPortraitData (SubResource)
##   "portrait_group": {
##  	 "portrait_2": GraphDialogsPortraitData (SubResource)
##  	 "portrait_3": GraphDialogsPortraitData (SubResource)
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
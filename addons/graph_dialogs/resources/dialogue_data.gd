@tool
class_name GraphDialogsDialogueData
extends Resource

## -----------------------------------------------------------------------------
## Dialogue Data Resource
## 
## This resource is used to store dialogue data from the graph editor.
## -----------------------------------------------------------------------------

## The dialogue data from the graph editor.
## This is a dictionary where each key is the ID (start id) of a dialogue branch
## and its value is a nested dictionary containing the nodes of that branch.
## This dictionary is structured as follows:
## [codeblock]
## {
##   "dialogue_1": {
##     "node_1": { ... },
##     "node_2": { ... },
##     },
##   "dialogue_2": {
##     "node_1": { ... },	
##     "node_2": { ... },
##     },
##   ...
##  }
## }[/codeblock]
@export var graph_data: Dictionary = {}
## A dictionary containing the dialogues for each dialogue ID.
## This dictionary is structured as follows:
## [codeblock]
## {
##   "dialogue_id_1": {
##     "locale_1": "Translated text in locale 1",
##     "locale_2": "Translated text in locale 2",
##     ...
##   },
##   ...
## }[/codeblock]
@export var dialogs: Dictionary = {}
## A dictionary containing the characters for each dialogue ID.
## This is a dictionary where each key is the dialogue ID 
## and its value is a dictionary of the characters with their UIDs.
## This dictionary is structured as follows:
## [codeblock]
## {
##   "dialogue_id_1": {
##     "Character 1": UID of the character resource,
##     "Character 2": UID of the character resource,
##     ...
##   },
##   "dialogue_id_2": { ... },
##   "dialogue_id_3": { ... },
##   ...
## }[/codeblock]
@export var characters: Dictionary = {}
## The path to the CSV file that contains the translated dialogue.
@export var csv_file_path: String = ""


## Returns a list of the start IDs from the graph data.
func get_start_ids() -> Array[String]:
	var dialogue_ids: Array[String] = []
	for dialogue_id in graph_data.keys():
		dialogue_ids.append(dialogue_id.replace("DIALOG_", ""))
	return dialogue_ids
@tool
class_name SproutyDialogsDialogueData
extends Resource

# -----------------------------------------------------------------------------
# Sprouty Dialogs Dialogue Data
# ----------------------------------------------------------------------------- 
## This resource stores the dialogue data from the graph editor.
##
## It includes the graph data, character references, dialogues and a reference
## to a CSV file for translations.
# -----------------------------------------------------------------------------

## The dialogue data from the graph editor.
## This is a dictionary where each key is the ID (start id) of a dialogue branch
## and its value is a nested dictionary containing the nodes of that branch.
## This dictionary is structured as follows:
## [codeblock]
## {
##   "dialogue_id_1": {
##     "node_1": { ... },
##     "node_2": { ... },
##     },
##   "dialogue_id_2": {
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
##     "locale_code_1": "Translated text in locale 1",
##     "locale_code_2": "Translated text in locale 2",
##     ...
##   },
##   ...
## }[/codeblock]
@export var dialogs: Dictionary = {}
## A dictionary containing the characters for each dialogue ID.
## This is a dictionary where each key is the dialogue ID 
## and its value is the characters associated with its UID.
## This dictionary is structured as follows:
## [codeblock]
## {
##   "dialogue_id_1": {
##     "character_name_1": UID of the character resource,
##     "character_name_2": UID of the character resource,
##     ...
##   },
##   ...
## }[/codeblock]
@export var characters: Dictionary = {}
## Reference to CSV file with the translations for the dialogues.
## This is the UID of the CSV file resource.
@export var csv_file_uid: int = -1


## Returns a list of the start IDs from the graph data.
func get_start_ids() -> Array[String]:
	var dialogue_ids: Array[String] = []
	for dialogue_id in graph_data.keys():
		dialogue_ids.append(dialogue_id)
	return dialogue_ids


## Returns a dictionary of the characters and their portraits for a given start ID.
## The start ID is the ID of the dialogue branch to get the characters from.
## The dictionary is structured as follows:
## [codeblock]
## {
##   "character_name_1": [portrait_name_1, portrait_name_2, ...],
##   "character_name_2": [portrait_name_1, portrait_name_2, ...],
##   ...
## }[/codeblock]
func get_portraits_on_dialog(start_id: String) -> Dictionary:
	var portraits: Dictionary = {}
	for node in graph_data[start_id].values():
		if node["node_type"] == "dialogue_node":
			if node["character"] == "":
				continue # Skip if no character or portrait is set
			if not portraits.has(node["character"]):
				portraits[node["character"]] = [node["portrait"]]
			else:
				portraits[node["character"]].append(node["portrait"])
	return portraits

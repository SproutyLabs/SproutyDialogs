@tool
class_name GraphDialogsDialogueData
extends Resource

## -----------------------------------------------------------------------------
## Dialogue Data Resource
## 
## This resource is used to store dialogue data for the graph editor.
## -----------------------------------------------------------------------------

## The dialogue data from the graph editor.
## This is a dictionary where each key is the ID (start id) of a dialogue branch
## and its value is a nested dictionary containing the nodes of that branch.
## This dictionary is structured as follows:
## [codeblock]
## {
##   "dialogue_1": {
##     "node_1": {
##          "node_index": 0,
##          "node_type": "type_1",
##          "to_node": ["node_2", "node_3"],
##          ...
##     },
##     "node_2": {
##          "node_index": 1,
##          "node_type": "type_2",
##          "to_node": ["node_3"],
##          ...
##     },
##   ...
## }[/codeblock]
@export var graph_data: Dictionary = {}
## List of characters that appear in the dialogue.
## This is an array of strings, where each string is the key name of a character.
@export var characters: Array[String] = []
## The path to the CSV file that contains the translated dialogue.
@export var csv_file_path: String = ""


## Returns a list of the dialogue IDs from the graph data.
func get_dialogue_ids() -> Array[String]:
	var dialogue_ids: Array[String] = []
	for dialogue_id in graph_data.keys():
		dialogue_ids.append(dialogue_id)
	return dialogue_ids
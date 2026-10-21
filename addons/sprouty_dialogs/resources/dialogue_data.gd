@tool
@icon("res://addons/sprouty_dialogs/editor/icons/event_nodes/dialogue.svg")
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
##     "character_key_name_1": UID of the character resource,
##     "character_key_name_2": UID of the character resource,
##     ...
##   },
##   ...
## }[/codeblock]
@export var characters: Dictionary = {}

## Reference to CSV file with the translations for the dialogues.
## This is the UID of the CSV file resource.
var csv_file_uid: int = -1


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


## Return all the character references count from the dialogue file
func get_all_character_references() -> Dictionary:
	var references = {}
	for start_id in graph_data.keys():
		for node in graph_data[start_id].values():
			if node.has("character"):
				if not references.has(node["character"]):
					references[node["character"]] = 1
				else:
					references[node["character"]] += 1
	return references


## Synchronizes the character references with the current key_name of each
## character file. The characters dictionary (key name to UID) and the
## 'character' reference on the dialogue nodes data are updated to the current
## file name of every character file referenced by UID.
## References with an invalid UID (e.g. when the character file was renamed
## or moved outside of the plugin editor) are recovered by the current key
## name of the character files, replacing the outdated key name and UID.
## Call it every time the dialogue file is loaded, and save the dialogue file
## again if this returns true, so the file is saved with the updated names.
## Returns true if any character reference was renamed.
func sync_character_references() -> bool:
	var renames: Dictionary = { # old key name -> old UID -> {key: new key, uid: new uid}
	}
	var recovered_cache: Dictionary = {} # Old key -> found character resource info
	var add_rename := func(old_key: String, old_uid: int, new_key: String,
			new_uid: int = old_uid) -> void:
		if not renames.has(old_key):
			renames[old_key] = {}
		renames[old_key][old_uid] = {"key": new_key, "uid": new_uid}
	
	for start_id in characters.keys():
		for key_name in characters[start_id].keys():
			var char_uid: int = characters[start_id][key_name]
			if renames.has(key_name) and renames[key_name].has(char_uid):
				continue # Character already processed
			if SproutyDialogsFileUtils.check_valid_uid_path(char_uid):
				# The character file still exists, use its current file name
				var file_name = ResourceUID.get_id_path(char_uid).get_file().get_basename()
				if file_name.is_empty() or file_name == key_name:
					continue
				add_rename.call(key_name, char_uid, file_name)
			else:
				# The UID is not valid anymore: the character file was renamed
				# or moved outside of the editor, so recover the reference by
				# the current file name / key name of the character file
				if not recovered_cache.has(key_name):
					var char_resource = SproutyDialogsFileUtils.find_character_resource_by_key(
							key_name)
					recovered_cache[key_name] = null
					if char_resource:
						var recovered_uid = ResourceSaver.get_resource_id_for_path(
								char_resource.resource_path, true)
						if recovered_uid != -1:
							recovered_cache[key_name] = [
								recovered_uid,
								char_resource.resource_path.get_file().get_basename()
							]
				if recovered_cache[key_name] == null:
					continue # The character reference cannot be healed by its UID
				add_rename.call(key_name, char_uid,
						recovered_cache[key_name][1], recovered_cache[key_name][0])
	
	if renames.is_empty():
		return false
	
	for start_id in characters.keys():
		var char_uids: Dictionary = characters[start_id]
		var renames_on_id: Dictionary = {}
		
		for old_key in renames.keys():
			if not char_uids.has(old_key):
				continue
			var old_uid: int = char_uids[old_key]
			if not renames[old_key].has(old_uid):
				continue
			var new_key: String = renames[old_key][old_uid]["key"]
			if new_key.is_empty() or (char_uids.has(new_key) and new_key != old_key):
				continue
			renames_on_id[old_key] = new_key
			char_uids[old_key] = renames[old_key][old_uid]["uid"]
		
		for old_key in renames_on_id.keys():
			var uid: int = char_uids[old_key]
			char_uids.erase(old_key)
			char_uids[renames_on_id[old_key]] = uid
		
		if not graph_data.has(start_id):
			continue
		for node_name in graph_data[start_id].keys():
			var node: Dictionary = graph_data[start_id][node_name]
			if node.has("character") and renames_on_id.has(node["character"]):
				node["character"] = renames_on_id[node["character"]]
	
	return true
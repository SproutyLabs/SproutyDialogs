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
## and its value is a dictionary with each character key name and its
## reference, stored as a subdictionary with the UID and the file path of the
## character resource, so the character can still be loaded by its path when
## the UID is no longer valid. This dictionary is structured as follows:
## [codeblock]
## {
##   "dialogue_id_1": {
##     "character_key_name_1": {
##       "uid": UID of the character resource,
##       "path": "res://path_to_the/character_file.tres",
##     },
##     "character_key_name_2": { ... },
##     ...
##   },
##   ...
## }[/codeblock]
@export var characters: Dictionary = {}

## Reference to CSV file with the translations for the dialogues.
## This is the UID of the CSV file resource.
@export_storage var csv_file_uid: int = -1


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
## character file. This updates:
## [br]- The legacy references that stored the character UID only, migrating them
##   to the current reference format (a subdictionary with "uid" and "path").
## [br]- The stored UID and file path of every reference with its current values
##   (e.g. when the stored file path is no longer the current location).
## [br]- The characters dictionary keys and the 'character' reference on the
##   dialogue nodes data with the current file name of every character file
##   referenced by UID or by path (key name to file name renaming).
## [br]
## Call it every time the dialogue file is loaded, and save the dialogue file
## again if this returns true, so the file is saved with the updated values.
## Returns true if any character reference was renamed or updated.
func sync_character_references() -> bool:
	var renames: Dictionary = { # old key name -> old UID -> renamed reference
	}
	var recovered_cache: Dictionary = {} # Old key -> found character reference
	var updated := false # References updated without any rename (e.g. normalized)
	var add_rename := func(old_key: String, old_uid: int, new_key: String,
			new_uid: int, new_path: String) -> void:
		if not renames.has(old_key):
			renames[old_key] = {}
		renames[old_key][old_uid] = {"uid": new_uid, "path": new_path}
		renames[old_key][old_uid]["key"] = new_key
	
	for start_id in characters.keys():
		for key_name in characters[start_id].keys():
			var reference = characters[start_id][key_name]
			if not reference is Dictionary:
				# Migrate legacy references storing only the character UID
				characters[start_id][key_name] = {
					"uid": reference if reference is int else -1,
					"path": "",
				}
				reference = characters[start_id][key_name]
				updated = true
			var char_uid: int = reference.get("uid", -1)
			var char_path: String = reference.get("path", "")
			
			if renames.has(key_name) and renames[key_name].has(char_uid):
				continue # Character already processed
			
			if SproutyDialogsFileUtils.check_valid_uid_path(char_uid):
				# The character file still exists on the UID path, so keep the
				# reference matched with its current path and file name
				var current_path: String = ResourceUID.get_id_path(char_uid)
				if char_path != current_path:
					reference["path"] = current_path
					updated = true
				var file_name = current_path.get_file().get_basename()
				if file_name.is_empty() or file_name == key_name:
					continue
				add_rename.call(key_name, char_uid, file_name, char_uid, current_path)
				continue
			
			if not char_path.is_empty() and FileAccess.file_exists(char_path):
				# The UID is no longer valid (e.g. the character file was
				# renamed or moved outside of the editor), but the stored file
				# path still points to the character file
				var file_name = char_path.get_file().get_basename()
				if file_name == key_name:
					# Only the reference needs to be updated, the key name is
					# already the current file name
					reference["uid"] = ResourceSaver.get_resource_id_for_path(
							char_path, true)
					updated = true
					continue
				var new_uid: int = ResourceSaver.get_resource_id_for_path(char_path, true)
				if new_uid != -1:
					add_rename.call(key_name, char_uid, file_name, new_uid, char_path)
				continue
			
			# The UID and the stored path are not valid anymore, so recover
			# the reference by the current file name / key name of the
			# project character files
			if not recovered_cache.has(key_name):
				var found = SproutyDialogsFileUtils.find_character_resource_by_key(
						key_name)
				recovered_cache[key_name] = null
				if found:
					var found_uid: int = ResourceSaver.get_resource_id_for_path(
							found.resource_path, true)
					# References with no resolvable UID (e.g. dialogs loaded
					# in game runs) are not rewritten, they keep the stored
					# values and are resolved by the resource loading fallbacks
					if found_uid != -1:
						recovered_cache[key_name] = {
							"key": found.resource_path.get_file().get_basename(),
							"uid": found_uid,
							"path": found.resource_path,
						}
			if recovered_cache[key_name] == null:
				continue # The character reference cannot be recovered
			var recovered: Dictionary = recovered_cache[key_name]
			add_rename.call(key_name, char_uid, recovered["key"],
					recovered["uid"], recovered["path"])
	
	if renames.is_empty():
		return updated
	
	for start_id in characters.keys():
		var char_refs: Dictionary = characters[start_id]
		var renames_on_id: Dictionary = {}
		
		for old_key in renames.keys():
			if not char_refs.has(old_key):
				continue
			var old_uid: int = char_refs[old_key].uid
			if not renames[old_key].has(old_uid):
				continue
			var rename: Dictionary = renames[old_key][old_uid]
			var new_key: String = rename["key"]
			if new_key.is_empty() or (char_refs.has(new_key) and new_key != old_key):
				continue
			renames_on_id[old_key] = new_key
			char_refs[old_key] = {"uid": rename["uid"], "path": rename["path"]}
		
		for old_key in renames_on_id.keys():
			var new_reference = char_refs[old_key]
			char_refs.erase(old_key)
			char_refs[renames_on_id[old_key]] = new_reference
		
		if not graph_data.has(start_id):
			continue
		for node_name in graph_data[start_id].keys():
			var node: Dictionary = graph_data[start_id][node_name]
			if node.has("character") and renames_on_id.has(node["character"]):
				node["character"] = renames_on_id[node["character"]]
	
	return true
@tool
extends VBoxContainer

## -----------------------------------------------------------------------------
## CSV Files Manager
##
## This script handles the CSV file path to the dialog data and the dialog data
## saving and loading from CSV files.
## -----------------------------------------------------------------------------

## Emitted when the CSV file path is changed.
signal csv_file_path_changed(path: String)

## File path field to set the CSV file path.
@onready var _path_field: GraphDialogsFileField = $FileField


func _ready():
	_path_field.file_path_changed.connect(_on_csv_file_path_changed)


## Returns the current CSV file path from the field.
func get_current_csv_path() -> String:
	return _path_field.get_value()


## Set the CSV file path in the file field.
func set_csv_path_on_field(path: String) -> void:
	_path_field.set_value(path)
	

#region === Dialogs translations ===============================================

## Save all graph dialogs on CSV file
func save_dialogs_on_csv(dialogs: Dictionary, path: String) -> void:
	var header = ["key"]
	var content = []
	
	for dialog_key in dialogs:
		var row = [dialog_key]
		for locale in dialogs[dialog_key]:
			if header.size() < dialogs[dialog_key].size() + 1:
				header.append(locale) # Set header
			row.append(dialogs[dialog_key][locale])
		content.append(row)
	
	GraphDialogsCSVFileManager.save_file(header, content, path)


## Load all dialogs from a CSV file to a dictionary.
## Returns a dictionary with the dialog data as:
## { dialog_key: {
##     locale_1: dialog_text,
##     locale_2: dialog_text,
##     ...
##     }
##   ...
## }
func load_dialogs_from_csv(path: String) -> Dictionary:
	var data := GraphDialogsCSVFileManager.load_file(path)
	if data.is_empty(): # If there is no data, an error occurred
		printerr("[Graph Dialogs] Cannot load dialogs from CSV file.")
		return {}
	var header = data[0]
	var dialogs := {}
	
	# Parse CSV data to a dictionary
	for row in data.slice(1, data.size() - 1):
		# Add a new dict for each dialog key
		var dialog_key = row[0]
		dialogs[dialog_key] = {}
		# Add each dialog in their respective locale
		for i in range(1, row.size()):
			dialogs[dialog_key][header[i]] = row[i]
	
	return dialogs

#endregion

#region === Character names translations =======================================

## Save character name translations on CSV file
func save_character_names_on_csv(name_data: Dictionary) -> void:
	var path = GraphDialogsTranslationManager.char_names_csv_path
	var csv_file = GraphDialogsCSVFileManager.load_file(path)
	var header = csv_file[0]
	var key_name = name_data.keys()[0]

	# Parse name data to an array and sort by header locales
	var row = [key_name]
	for i in range(header.size()):
		if header[i] == "key":
			continue
		if name_data[key_name].has(header[i]):
			row.append(name_data[key_name][header[i]])
		else:
			row.append("EMPTY")
	
	# The locales that not exist in header are added to the end of the row
	for i in range(name_data[key_name].size()):
		if not header.has(name_data[key_name].keys()[i]):
			row.append(name_data[key_name].values()[i])
			header.append(name_data[key_name].keys()[i])

	GraphDialogsCSVFileManager.update_row(path, header, row)


## Load character name translations from a CSV file to a dictionary.
## Returns a dictionary with the character names as:
## { key_name: {
## 		{ locale_1: character_name_1,
##  	  locale_2: character_name_2,
## 		  ...
## 		}
##    }
## }
func load_character_names_from_csv(key_name: String) -> Dictionary:
	var path = GraphDialogsTranslationManager.char_names_csv_path
	var data := GraphDialogsCSVFileManager.load_file(path)
	if data.is_empty():
		printerr("[Graph Dialogs] Cannot load character names from CSV file.")
		return {}
	
	# Get the row with the key name
	var row = data.filter(
		func(item: Array) -> bool:
			return item[0] == key_name
	)
	
	if row.is_empty():
		# If the key is not found, return an empty template dictionary
		var dict = {key_name: {}}
		for i in range(data[0].size() - 1):
			dict[key_name][data[0][i + 1]] = ""
		return dict
	
	# Get the names and parse to a dictionary
	var names = row[0].slice(1, row[0].size())
	var dict = {key_name: {}}
	for i in range(names.size()):
		dict[key_name][data[0][i + 1]] = names[i]
	
	return dict

#endregion


## Set CSV file path to the current data file
func _on_csv_file_path_changed(path: String) -> void:
	csv_file_path_changed.emit(path)
	_path_field.set_value(path)
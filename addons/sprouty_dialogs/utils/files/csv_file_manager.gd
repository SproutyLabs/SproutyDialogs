class_name SproutyDialogsCSVFileManager
extends RefCounted

# -----------------------------------------------------------------------------
# Sprouty Dialogs CSV File Manager
# -----------------------------------------------------------------------------
## This class handles CSV files operations for saving and loading
## translations. It provides methods to handle dialogs and character
## names translations with CSV files.
# -----------------------------------------------------------------------------


## Save data to a CSV file
## The data is provided as an array of arrays, where each inner array
## represents a row in the CSV file. The header is an array representing
## the first row of the CSV file.
static func save_file(header: Array, data: Array, file_path: String) -> void:
	# Open file or create it for writing data
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	
	if file == null: # Check if file is opened successfully
		printerr("[Sprouty Dialogs] Cannot save file. Open file error: %s"
				% [FileAccess.get_open_error()])
		return
	# Store header in csv file
	file.store_csv_line(PackedStringArray(header), ",")
	
	# Store data by rows in csv file
	if not data.is_empty():
		for row in data:
			if row != [] and row.count("EMPTY") != header.size(): # Skip empty rows
				file.store_csv_line(PackedStringArray(row), ",")
	else:
		# Add empty row to avoid translation import error
		var placeholder = []
		placeholder.resize(header.size())
		placeholder.fill("EMPTY")
		file.store_csv_line(PackedStringArray(placeholder), ",")
	file.close()


## Load data from a CSV file
## Returns an array with the CSV data
static func load_file(file_path: String) -> Array:
	# Check if file exists
	if FileAccess.file_exists(file_path):
		# Open file for reading data
		var file := FileAccess.open(file_path, FileAccess.READ)

		if file == null: # Check if file is opened successfully
			printerr("[Sprouty Dialogs] Cannot load file. Open file error: %s"
					% [FileAccess.get_open_error()])
			return []
		# Read each line from the file
		var data := []
		while !file.eof_reached():
			var csv_data: Array = file.get_csv_line()
			if csv_data != []: # Skip empty lines
				data.append(csv_data) # Add row to an array
		
		file.close()
		return data
	else: # File does not exist at the given path
		printerr("[Sprouty Dialogs] File at '%s' does not exist" % [file_path])
		return []
	return []


## Add or update a row in a CSV file
## If the row with the same key exists, it will be updated.
## If not, it will be added to the end of the file.
static func update_row(file_path: String, header: Array, row: Array) -> void:
	# Load the CSV file
	var csv_data = load_file(file_path)
	var content = csv_data.slice(1, csv_data.size())

	# Check if the CSV file is empty
	if csv_data.size() == 0:
		save_file(header, [row], file_path)
		return
	
	# Update or add the row
	var row_updated = false
	for i in range(content.size()):
		# Check if the row already exists by key
		if content[i][0] == "EMPTY":
			content = []
			break
		if content[i][0] == row[0]:
			content[i] = row
			row_updated = true
			break
	
	# If the row was not found, add it
	if not row_updated:
		content.append(row)
	
	content = content.filter(func(x): return x != [""]) # Remove empty rows
	
	# Save the updated CSV file
	save_file(header, content, file_path)


#region === Dialogs translations ===============================================

## Create a new CSV template file
## Returns the path of the created file or an empty string if an error occurred
static func new_csv_template_file(name: String) -> String:
	var csv_files_path: String = SproutyDialogsSettingsManager.get_setting("csv_translations_folder")
	if not DirAccess.dir_exists_absolute(csv_files_path):
		printerr("[Sprouty Dialogs] Cannot create file, need a directory path to CSV translation files."
				+" Please set 'CSV files path' in Settings > Translation.")
		return ""
	var path = csv_files_path + "/" + name.split(".")[0] + ".csv"
	var header = ["keys"]
	for locale in SproutyDialogsSettingsManager.get_setting("locales"):
		header.append(locale)
	save_file(header, [], path)
	return path


## Save all dialogs from a dictionary to a CSV file.
## Update existing rows or add new ones if the dialog key does not exist
## and save the file with all the dialogs without removing any existing data.
static func save_dialogs_on_csv(dialogs: Dictionary, path: String) -> void:
	var header = ["keys"]
	var csv_data = []
	
	# Collect all locales for the header
	for dialog_key in dialogs:
		for locale in dialogs[dialog_key]:
			if not header.has(locale) and locale != "default":
				header.append(locale)
	
	# Load existing data if file exists
	if FileAccess.file_exists(path):
		csv_data = load_file(path)
	else:
		csv_data = [header]

	# Build a dictionary for fast lookup
	var existing_rows := {}
	for row in csv_data.slice(1, csv_data.size()):
		if row.size() > 0:
			existing_rows[row[0]] = row
	
	# Update or add each dialog row
	for dialog_key in dialogs:
		var row = [dialog_key]
		for i in range(1, header.size()):
			var locale = header[i]
			if dialogs[dialog_key].has(locale):
				row.append(dialogs[dialog_key][locale])
			else:
				row.append("EMPTY")
			existing_rows[dialog_key] = row
    
    # Prepare final content
	var content = []
	for key in existing_rows.keys():
		content.append(existing_rows[key])
	
	# remove empty rows
	content = content.filter(func(x): return x != [""])
	save_file(header, content, path)

	
## Load all dialogs from a CSV file to a dictionary.
## Returns a dictionary with the dialogue data as:
## [codeblock]
## { 
##    "dialogue_id_1": {
##    	"locale_code_1": "Translated text in locale 1",
##    	"locale_code_2": "Translated text in locale 2",
##    	...
##    },
##   ...
## }[/codeblock]
static func load_dialogs_from_csv(path: String) -> Dictionary:
	var data := load_file(path)
	if data.is_empty(): # If there is no data, an error occurred
		printerr("[Sprouty Dialogs] Cannot load dialogs from CSV file.")
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
			if header.size() > i and row.size() > i:
				dialogs[dialog_key][header[i]] = row[i]
	
	return dialogs

#endregion

#region === Character names translations =======================================

## Save character name translations on the CSV file.
static func save_character_names_on_csv(key_name: String, name_data: Dictionary) -> void:
	var char_names_csv = SproutyDialogsSettingsManager.get_setting("character_names_csv")
	if not SproutyDialogsFileUtils.check_valid_uid_path(char_names_csv):
		printerr("[Sprouty Dialogs] Cannot save character name translations, no CSV file set."
				+" Please set 'Character names CSV' in Settings > Characters.")
		return
	
	# Load the CSV file
	var path: String = ResourceUID.get_id_path(char_names_csv)
	var csv_file := load_file(path)
	var header = csv_file[0]

	# Parse name data to an array and sort by header locales
	var row = [key_name.to_upper() + "_CHAR"]
	for i in range(header.size()):
		if header[i] == "keys":
			continue
		if name_data.has(header[i]):
			row.append(name_data[header[i]])
		else:
			row.append("EMPTY")
	
	# The locales that not exist in header are added to the end of the row
	for i in range(name_data.size()):
		if not header.has(name_data.keys()[i]) and name_data.keys()[i] != "default":
			row.append(name_data.values()[i])
			header.append(name_data.keys()[i])

	update_row(path, header, row)


## Load character name translations from a CSV file to a dictionary.
## Returns a dictionary with the character names as:
## [codeblock]
## { 
##    "locale_code_1": "Translated name in locale 1",
##    "locale_code_2": "Translated name in locale 2",
##    ...
## }[/codeblock]
static func load_character_names_from_csv(key_name: String) -> Dictionary:
	var char_names_csv = SproutyDialogsSettingsManager.get_setting("character_names_csv")
	if not SproutyDialogsFileUtils.check_valid_uid_path(char_names_csv):
		printerr("[Sprouty Dialogs] Cannot load character names translations, no CSV file set."
				+" Please set 'Character names CSV' in Settings > Characters.")
		return {}
	
	# Load the CSV file
	var path: String = ResourceUID.get_id_path(char_names_csv)
	var data := load_file(path)
	if data.is_empty():
		printerr("[Sprouty Dialogs] Cannot load character names from CSV file.")
		return {}
	
	# Get the row with the key name
	var row = data.filter(
		func(item: Array) -> bool:
			return item[0] == key_name
	)
	
	if row.is_empty():
		# If the key is not found, return an empty template dictionary
		var dict = {}
		for i in range(data[0].size() - 1):
			dict[data[0][i + 1]] = ""
		return dict
	
	# Get the names and parse to a dictionary
	var names = row[0].slice(1, row[0].size())
	var dict = {}
	for i in range(names.size()):
		dict[data[0][i + 1]] = names[i]
	
	return dict

#endregion
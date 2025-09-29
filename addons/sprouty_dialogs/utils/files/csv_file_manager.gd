class_name EditorSproutyDialogsCSVFileManager
extends RefCounted

# -----------------------------------------------------------------------------
# Sprouty Dialogs CSV File Manager
# -----------------------------------------------------------------------------
## This class handles CSV files operations for saving and loading
## translations. It provides methods to handle dialogs and character
## names translations with CSV files.
# -----------------------------------------------------------------------------


## Save data to a CSV file
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
			if row != []: # Skip empty rows
				file.store_csv_line(PackedStringArray(row), ",")
	else:
		# Add empty row to avoid translation import error
		var placeholder = []
		placeholder.resize(header.size())
		placeholder.fill("EMPTY")
		file.store_csv_line(PackedStringArray(placeholder), ",")
	file.close()


## Load data from a CSV file
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
static func new_csv_template_file(name: String) -> String:
	var csv_files_path: String = EditorSproutyDialogsSettingsManager.get_setting("csv_translations_folder")
	if not DirAccess.dir_exists_absolute(csv_files_path):
		printerr("[Sprouty Dialogs] Cannot create file, need a directory path to CSV translation files."
				+" Please set 'CSV files path' in Settings > Translation.")
		return ""
	var path = csv_files_path + "/" + name.split(".")[0] + ".csv"
	var header = ["key"]
	for locale in EditorSproutyDialogsSettingsManager.get_setting("locales"):
		header.append(locale)
	save_file(header, [], path)
	return path


## Save all Sprouty Dialogs on CSV file
## Update existing rows or add new ones if the dialog key does not exist
## and save the file with all the dialogs without removing any existing data.
static func save_dialogs_on_csv(dialogs: Dictionary, path: String) -> void:
	var header = ["key"]
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
## { dialog_key: {
##     locale_1: dialog_text,
##     locale_2: dialog_text,
##     ...
##     }
##   ...
## }
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
			dialogs[dialog_key][header[i]] = row[i]
	
	return dialogs

#endregion

#region === Character names translations =======================================

## Save character name translations on CSV file
static func save_character_names_on_csv(name_data: Dictionary) -> void:
	var char_names_csv = EditorSproutyDialogsSettingsManager.get_setting("character_names_csv")
	if char_names_csv == -1:
		printerr("[Sprouty Dialogs] Cannot save character name translations, no CSV file set."
				+" Please set 'Character names CSV' in Settings > Characters.")
		return
	if not ResourceUID.has_id(char_names_csv):
		printerr("[Sprouty Dialogs] Cannot load character names translations, no valid CSV file set."
				+" Please set a valid 'Character names CSV' in Settings > Characters.")
		return
	
	# Load the CSV file
	var path: String = ResourceUID.get_id_path(char_names_csv)
	if not FileAccess.file_exists(path):
		printerr("[Sprouty Dialogs] Cannot load character names translations, CSV file: "
				+ path + " does not exist. Please set a valid 'Character names CSV' in Settings > Characters.")
		return
	var csv_file := load_file(path)
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
		if not header.has(name_data[key_name].keys()[i]) and name_data[key_name].keys()[i] != "default":
			row.append(name_data[key_name].values()[i])
			header.append(name_data[key_name].keys()[i])

	update_row(path, header, row)


## Load character name translations from a CSV file to a dictionary.
## Returns a dictionary with the character names as:
## { key_name: {
## 		{ locale_1: character_name_1,
##  	  locale_2: character_name_2,
## 		  ...
## 		}
##    }
## }
static func load_character_names_from_csv(key_name: String) -> Dictionary:
	var char_names_csv = EditorSproutyDialogsSettingsManager.get_setting("character_names_csv")
	if char_names_csv == -1:
		printerr("[Sprouty Dialogs] Cannot load character names translations, no CSV file set."
				+" Please set 'Character names CSV' in Settings > Characters.")
		return {}
	if not ResourceUID.has_id(char_names_csv):
		printerr("[Sprouty Dialogs] Cannot load character names translations, no valid CSV file set."
				+" Please set a valid 'Character names CSV' in Settings > Characters.")
		return {}
	
	# Load the CSV file
	var path: String = ResourceUID.get_id_path(char_names_csv)
	if not FileAccess.file_exists(path):
		printerr("[Sprouty Dialogs] Cannot load character names translations, CSV file: "
				+ path + " does not exist. Please set a valid 'Character names CSV' in Settings > Characters.")
		return {}
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
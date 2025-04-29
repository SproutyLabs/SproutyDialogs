class_name GraphDialogsJSONFileManager
extends RefCounted

## ------------------------------------------------------------------
## JSON files manager
##
## This class is responsible for saving and loading JSON files.
## ------------------------------------------------------------------


## Save data to a JSON file
static func save_file(data: Dictionary, file_path: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		printerr("[JSONFileManager] %s" % [FileAccess.get_open_error()])
		return
	
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()


## Load data from a JSON file
static func load_file(file_path: String) -> Variant:
	if FileAccess.file_exists(file_path):
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			printerr("[JSONFileManager] %s" % [FileAccess.get_open_error()])
			return null
		
		var content := file.get_as_text()
		file.close()
		
		# Parse content to a dictionary
		var data := JSON.parse_string(content)
		if data == null:
			printerr("[JSONFileManager] Cannot parse %s as a json_string: (%s)"
			% [file_path, content])
			return null
		else:
			return data
	else:
		printerr("[JSONFileManager] Cannot open non-existing file at %s"
		% [file_path])
		return null

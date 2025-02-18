class_name GDialogsCSVFileManager
extends RefCounted

## ------------------------------------------------------------------
## Save and load data from CSV files
## ------------------------------------------------------------------

static func save_file(header : Array, data : Array, file_path : String) -> void:
	# Save data to a CSV file
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		printerr("[CSVFileManager] %s" % [FileAccess.get_open_error()])
		return
	
	# Store header in csv file
	file.store_csv_line(PackedStringArray(header), ",")
	
	# Store data by rows in csv file
	if not data.is_empty():
		for row in data:
			if row.size() != header.size():
				printerr("[CSVFileManager] The data has %d columns," +\
					"does not match with header size (%d)" % [row.size(), header.size()])
				return
			file.store_csv_line(PackedStringArray(row), ",")
	else: # Add empty row to avoid translation import error
		var placeholder = []
		placeholder.resize(header.size())
		placeholder.fill("EMPTY")
		file.store_csv_line(PackedStringArray(placeholder), ",")
	file.close()

static func load_file(file_path : String) -> Variant:
	# Load data from a CSV file
	if FileAccess.file_exists(file_path):
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			printerr("[CSVFileManager] %s" % [FileAccess.get_open_error()])
			return null
		
		var content := file.get_as_text()
		file.close()
		
		# Parse content to string arrays
		var raw_rows := content.split("\n")
		var data := []
		
		for row in raw_rows:
			var row_data := row.split(",")
			data.append(row)
		return data
	else: 
		printerr("[CSVFileManager] Cannot open non-existing file at %s" 
		% [file_path])
		return null
	return null

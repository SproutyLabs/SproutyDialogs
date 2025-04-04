class_name GDialogsCSVFileManager
extends RefCounted

## ------------------------------------------------------------------
## CSV files manager
##
## This class is responsible for saving and loading CSV files.
## ------------------------------------------------------------------


## Save data to a CSV file
static func save_file(header: Array, data: Array, file_path: String) -> void:
	# Open file or create it for writing data
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	
	if file == null: # Check if file is opened successfully
		printerr("[CSVFileManager] %s" % [FileAccess.get_open_error()])
		return
	# Store header in csv file
	file.store_csv_line(PackedStringArray(header), ",")
	
	# Store data by rows in csv file
	if not data.is_empty():
		for row in data:
			if row.size() != header.size():
				printerr("[CSVFileManager] The data has %d columns," + \
					"does not match with header size (%d)" % [row.size(), header.size()])
				return
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
			printerr("[CSVFileManager] %s" % [FileAccess.get_open_error()])
			return []
		# Read each line from the file
		var data := []
		while !file.eof_reached():
			var csv_data: Array = file.get_csv_line()
			data.append(csv_data) # Add row to an array
		
		file.close()
		return data
	else: # File does not exist at the given path
		printerr("[CSVFileManager] Cannot open non-existing file at %s"
		% [file_path])
		return []
	return []


## Add or update a row in a CSV file
static func update_row(file_path: String, header: Array, row: Array) -> void:
	# Load the CSV file
	var csv_data = load_file(file_path)
	
	# Check if the CSV file is empty
	if csv_data.size() == 0:
		save_file(header, [row], file_path)
		return
	
	# Update or add the row
	var row_updated = false
	for i in range(1, csv_data.size()):
		# Check if the row already exists by key
		if csv_data[i][0] == row[0]:
			csv_data[i] = row
			row_updated = true
			break
	
	# If the row was not found, add it
	if not row_updated:
		csv_data.append(row)
	
	# Save the updated CSV file
	save_file(header, csv_data, file_path)
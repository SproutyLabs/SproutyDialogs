@tool
class_name GraphDialogsFileUtils
extends Node

## -----------------------------------------------------------------------------
## File Utils
##
## This module is responsible for some file operations and references.
## -----------------------------------------------------------------------------

## Last used paths for file dialogs
static var recent_file_paths: Dictionary = {
	"graph_dialogs_files": "res://",
	"dialogue_files": "res://",
	"character_files": "res://",
	"csv_dialog_files": "res://",
	"text_box_files": "res://",
	"portrait_files": "res://",
}


## Get the last used path for a file in a file dialog
static func get_recent_file_path(file_type: String) -> String:
	if recent_file_paths.has(file_type):
		return recent_file_paths[file_type]
	return "res://"


## Set the last used path for a file in a file dialog
static func set_recent_file_path(file_type: String, path: String) -> void:
	recent_file_paths[file_type] = path.get_base_dir()


## Check if the path has valid extension
static func check_valid_extension(path: String, extensions: Array) -> bool:
	if path.is_empty():
		return false
	for ext in extensions:
		if path.ends_with(ext.replace("*", "")):
			return true
	return false


#region === Translation ========================================================

## Collect translation files from the CSV folder
## and add them to the project settings translations.
## This allow to use the translations from CSV files in the project.
static func collect_translations() -> void:
	var path = GraphDialogsSettings.get_setting("csv_translations_folder")
	if path.is_empty():
		printerr("[Graph Dialogs] Cannot collect translations, need a path to CSV translation files.")
		return
	var translation_files := _get_translation_files(path)
	var all_translation_files: Array = ProjectSettings.get_setting(
			'internationalization/locale/translations', [])
	
	# Add new translation files to the old ones
	for file in translation_files:
		if not file in all_translation_files:
			all_translation_files.append(file)
	
	# Keep only the translation of setted locales
	var valid_translation_files = []
	for file in all_translation_files:
		for locale in GraphDialogsSettings.get_setting("locales"):
			if file.split(".")[-2] == locale:
				valid_translation_files.append(file)
				break
	
	ProjectSettings.set_setting(
			'internationalization/locale/translations',
			PackedStringArray(valid_translation_files))
	ProjectSettings.save()

	print("[Graph Dialogs] Translation files collected.")


## Get the translation files from csv folder and its subfolders
static func _get_translation_files(path: String) -> Array:
	var translation_files := []
	var subfolders = Array(DirAccess.get_directories_at(path)).map(
			func(folder): path + "/" + folder)
	subfolders.insert(0, path) # Add the main folder

	for folder in subfolders:
		for file in DirAccess.get_files_at(folder):
			if file.ends_with('.translation'):
				file = folder + "/" + file
				if not file in translation_files:
					translation_files.append(file)
	return translation_files

#endregion
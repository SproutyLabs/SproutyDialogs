class_name GDialogsTranslationManager
extends Resource

## -----------------------------------------------------------------------------
## Translation Manager
##
## This class manages the translation settings and operations globally for the
## dialog system.
## -----------------------------------------------------------------------------

## Path to the translation settings data
const DATA_PATH = "res://addons/graph_dialog_system/settings/translation_settings.json"
const DEFAULT_CHAR_NAMES_CSV = "character_names.csv"

## Translation settings container
static var translation_settings: HSplitContainer

## Path to the CSV translation files
static var csv_files_path: String = "":
	set(value):
		csv_files_path = value
		if translation_settings != null:
			translation_settings.csv_folder_field.set_value(value)
		save_translation_setting("csv_files_path", value)

## Path to the CSV with character names translations
static var char_names_csv_path: String = "":
	set(value):
		char_names_csv_path = value
		if translation_settings != null:
			translation_settings.char_names_csv_field.set_value(value)
		save_translation_setting("char_names_csv_path", value)

## Default locale selected
static var default_locale: String = ""
## Testing locale selected
static var testing_locale: String = ""
## Available locales in the project
static var locales: Array = []


## Save the translation settings in the settings data
static func save_all_translation_settings() -> void:
	var data := {
		"translation_settings": {
			"csv_files_path": csv_files_path,
			"char_names_csv_path": char_names_csv_path,
			"default_locale": default_locale,
			"testing_locale": testing_locale,
			"locales": locales
		}
	}
	GDialogsJSONFileManager.save_file(data, DATA_PATH)


## Save a specific translation setting in the settings data
static func save_translation_setting(key: String, value: Variant) -> void:
	var data = GDialogsJSONFileManager.load_file(DATA_PATH)
	data.translation_settings[key] = value
	GDialogsJSONFileManager.save_file(data, DATA_PATH)


## Load translation settings from settings data
static func load_translation_settings() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		set_default_translation_settings()
		save_all_translation_settings()
		return
	
	var data = GDialogsJSONFileManager.load_file(DATA_PATH)
	csv_files_path = data.translation_settings.csv_files_path
	char_names_csv_path = data.translation_settings.char_names_csv_path
	default_locale = data.translation_settings.default_locale
	testing_locale = data.translation_settings.testing_locale
	locales = data.translation_settings.locales
	
	# If settings are empty, set initial settings
	if locales.is_empty():
		set_default_translation_settings()
	elif default_locale.is_empty():
		default_locale = locales[0]
	elif testing_locale.is_empty():
		testing_locale = locales[0]


## Set the default translation settings
static func set_default_translation_settings() -> void:
	# Set the editor language as the default locale
	var settings = EditorInterface.get_editor_settings()
	var editor_lang = settings.get_setting("interface/editor/editor_language")
	default_locale = editor_lang
	testing_locale = editor_lang
	locales.append(editor_lang)


## Create a new CSV template file
static func new_csv_template_file(name: String) -> String:
	if csv_files_path.is_empty():
		printerr("[Graph Dialogs] Cannot create file, need a path to CSV translation files.")
		return ""
	var path = csv_files_path + "/" + name.split(".")[0] + ".csv"
	var header = ["key"]
	for locale in locales:
		header.append(locale)
	GDialogsCSVFileManager.save_file(header, [], path)
	return path


## Collect translation files from the CSV folder
static func collect_translations(path: String = csv_files_path) -> void:
	if path.is_empty():
		printerr("[Graph Dialogs] Cannot collect translations, need a path to CSV translation files.")
		return
	var translation_files := get_translation_files(path)
	var all_translation_files: Array = ProjectSettings.get_setting(
			'internationalization/locale/translations', [])
	
	# Add new translation files to the old ones
	for file in translation_files:
		if not file in all_translation_files:
			all_translation_files.append(file)
	
	# Keep only the translation of setted locales
	var valid_translation_files = []
	for file in all_translation_files:
		for locale in locales:
			if file.split(".")[-2] == locale:
				valid_translation_files.append(file)
				break
	
	ProjectSettings.set_setting(
			'internationalization/locale/translations',
			PackedStringArray(valid_translation_files))
	ProjectSettings.save()


## Get the translation files from csv folder and its subfolders
static func get_translation_files(path: String) -> Array:
	var translation_files := []
	var subfolders = Array(DirAccess.get_directories_at(path)).map(
			func(folder): path + "/" + folder)
	subfolders.insert(0, path) # Add the main folder

	for folder in subfolders:
		for file in DirAccess.get_files_at(folder):
			if file.ends_with('.translation'):
				if not file in translation_files:
					translation_files.append(file)
	return translation_files

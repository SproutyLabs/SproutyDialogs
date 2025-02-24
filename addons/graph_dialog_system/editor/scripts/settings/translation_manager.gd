class_name GDialogsTranslationManager
extends Resource

## ------------------------------------------------------------------
## Handle translation on dialogs
## ------------------------------------------------------------------

const DATA_PATH = "res://addons/graph_dialog_system/editor/settings/translation_settings.json"

static var csv_files_path : String = ""
static var default_locale : String = ""
static var testing_locale : String = ""
static var locales : Array = []

static var translation_settings : HSplitContainer

static func save_translation_settings() -> void:
	# Save translation settings in settings data
	var data := {
		"translation_settings": {
			"csv_files_path" : csv_files_path,
			"default_locale" : default_locale,
			"testing_locale" : testing_locale,
			"locales" : locales
		}
	}
	GDialogsJSONFileManager.save_file(data, DATA_PATH)

static func load_translation_settings() -> void:
	# Load translation settings from settings data
	if not FileAccess.file_exists(DATA_PATH):
		set_default_translation_settings()
		save_translation_settings()
		return
	
	var data = GDialogsJSONFileManager.load_file(DATA_PATH)
	csv_files_path = data.translation_settings.csv_files_path
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

static func set_default_translation_settings() -> void:
	# Set the editor language as the default locale
	var settings = EditorInterface.get_editor_settings()
	var editor_lang = settings.get_setting("interface/editor/editor_language")
	default_locale = editor_lang
	testing_locale = editor_lang
	locales.append(editor_lang)

static func new_csv_template_file(name : String) -> String:
	# Create new csv file with selected locales template
	if csv_files_path.is_empty(): 
		printerr("[Graph Dialogs] Cannot create file, need a path to CSV translation files.")
		return ""
	
	var path = csv_files_path + "/" + name.split(".")[0] + ".csv"
	var header = ["key"]
	
	for locale in locales:
		header.append(locale)
	
	GDialogsCSVFileManager.save_file(header, [], path)
	return path

static func collect_translations(path : String = csv_files_path) -> void:
	# Collect translation files and add to the project settings
	if path.is_empty(): 
		printerr("[Graph Dialogs] Cannot collect translations, need a path to CSV translation files.")
		return
	
	var translation_files := []
	var all_translation_files: Array = ProjectSettings.get_setting(
			'internationalization/locale/translations', [])
	
	# Collect translation files from csv folder
	for file in DirAccess.get_files_at(path):
		if file.ends_with('.translation'):
			if not file in translation_files:
				translation_files.append(file)
	
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

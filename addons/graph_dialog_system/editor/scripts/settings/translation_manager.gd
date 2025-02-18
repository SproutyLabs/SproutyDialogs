class_name GDialogsTranslationManager
extends Resource

## ------------------------------------------------------------------
## Handle translation
## ------------------------------------------------------------------

static var csv_files_path : String = ""
static var default_locale : String = ""
static var testing_locale : String = ""
static var locales : Array = []

static func save_translation_settings():
	# Save translation settings in settings data
	var data := {
		"translation": {
			"csv_files_path" : csv_files_path,
			"default_locale" : default_locale,
			"testing_locale" : testing_locale,
			"locales" : locales
		}
	}
	GDialogsSettingsData.translation_settings = data
	GDialogsSettingsData.save_settings()

static func load_translation_settings():
	# Load translation settings from settings data
	GDialogsSettingsData.load_settings()
	var data = GDialogsSettingsData.translation_settings
	
	csv_files_path = data.csv_files_path
	default_locale = data.csv_files_path
	testing_locale = data.testing_locale
	locales = data.locales

static func new_csv_template_file(name : String) -> String:
	# Create new csv file with selected locales template
	var path = csv_files_path + "/" + name.split(".")[0] + ".csv"
	var header = ["key"]
	
	for locale in locales:
		header.append(locale)
	
	GDialogsCSVFileManager.save_file(header, [], path)
	return path

static func collect_translations(path : String = csv_files_path) -> void:
	# Collect translation files and add to the project settings
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

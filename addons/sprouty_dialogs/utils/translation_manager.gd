@tool
class_name SproutyDialogsTranslationManager
extends RefCounted

# -----------------------------------------------------------------------------
# Sprouty Dialogs Translation Manager
# -----------------------------------------------------------------------------
## This class manages the translations for the Sprouty Dialogs plugin.
## It provides methods to load and manage translations from CSV files.
# -----------------------------------------------------------------------------


## Returns the translated dialog text for a given key in a dialogue data
static func get_translated_dialog(key: String,
		dialog_data: SproutyDialogsDialogueData) -> String:
	if SproutyDialogsSettingsManager.get_setting("enable_translations"):
		# If translation is enabled and using CSV, use the translation server
		if SproutyDialogsSettingsManager.get_setting("use_csv_files"):
			return TranslationServer.translate(key)
		else: # Otherwise, get the dialog from the dialog resource
			var locale = TranslationServer.get_locale()
			if not dialog_data.dialogs.has(key):
				printerr("[Sprouty Dialogs] No dialogue found for key: " + key)
				return ""
			if not dialog_data.dialogs[key].has(locale):
				printerr("[Sprouty Dialogs] No translation found for key '" + key
					+"' in locale: " + locale + ". Using default dialog instead.")
				locale = "default"
			return dialog_data.dialogs[key][locale]
	else: # If translation is not enabled, use the default dialog text
		if not dialog_data.dialogs.has(key):
				printerr("[Sprouty Dialogs] No dialogue found for key: " + key)
				return ""
		return dialog_data.dialogs[key]["default"]


## Returns the translated character name for a given key in a character data
static func get_translated_character_name(key_name: String,
		character_data: SproutyDialogsCharacterData) -> String:
	if key_name == "": return "" # No character
	if SproutyDialogsSettingsManager.get_setting("enable_translations") \
			and SproutyDialogsSettingsManager.get_setting("translate_character_names"):
		# If translation is enabled and using CSV, use the translation server
		if SproutyDialogsSettingsManager.get_setting("use_csv_for_character_names"):
			return TranslationServer.translate(key_name.to_upper() + "_CHAR")
		else:
			var locale = TranslationServer.get_locale()
			if not character_data:
				printerr("[Sprouty Dialogs] No character data found for character: " + key_name)
				return key_name
			if not character_data.display_name.has(locale):
				printerr("[Sprouty Dialogs] No translation found for character '"
					+ key_name + "' in locale: " + locale + ". Using default display name instead.")
				locale = "default"
			 # Otherwise, get the name from the dialog resource
			return character_data.display_name[locale]
	else:
		if not character_data:
			printerr("[Sprouty Dialogs] No character data found for character: " + key_name)
			return key_name
		# If translation is not enabled, return the default display name
		return character_data.display_name["default"]


#region === Collect Translations ===============================================

## Collect translation files from the CSV folder
## and add them to the project settings translations.
## This allow to use the translations from CSV files in the project.
static func collect_translations() -> void:
	var path = SproutyDialogsSettingsManager.get_setting("csv_translations_folder")
	if path.is_empty():
		printerr("[Sprouty Dialogs] Cannot collect translations, need a path to CSV translation files.")
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
		if not FileAccess.file_exists(file):
			continue # Skip files that do not exist
		if SproutyDialogsSettingsManager.get_setting("locales").has(file.split(".")[-2]):
			valid_translation_files.append(file)
	
	ProjectSettings.set_setting(
			'internationalization/locale/translations',
			PackedStringArray(valid_translation_files))
	ProjectSettings.save()

	print("[Sprouty Dialogs] Translation files collected.")


## Get the translation files from CSV folder and its subfolders
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

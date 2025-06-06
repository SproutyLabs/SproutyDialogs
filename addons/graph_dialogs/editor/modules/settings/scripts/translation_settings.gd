@tool
extends HSplitContainer

## -----------------------------------------------------------------------------
## Translation settings
##
## This script handles the translation settings in settings tab. It allows to
## select the locales in the project, the default and testing locales, and the 
## folder where the CSV files are stored.
## -----------------------------------------------------------------------------

## Triggered when the locales change
signal locales_changed
## Triggered when the default locale changes
signal default_locale_changed
## Triggered when the testing locale changes
signal testing_locale_changed

## Use translation toggle
@onready var _use_translation_toggle: CheckButton = %UseTranslationToggle
## Use CSV files toggle
@onready var _use_csv_files_toggle: CheckButton = %UseCSVFilesToggle
## Translate character names toggle
@onready var _translate_names_toggle: CheckButton = %TranslateNamesToggle

## CSV folder path field
@onready var csv_folder_field: MarginContainer = %CSVFolderField
## Character names CSV path field
@onready var char_names_csv_field: MarginContainer = %CharNamesCSVField

## Default locale dropdown
@onready var default_locale_dropdown: OptionButton = %DefaultLocale/OptionButton
## Testing locale dropdown
@onready var testing_locale_dropdown: OptionButton = %TestingLocale/OptionButton
## Locales selector container
@onready var locales_selector: VBoxContainer = %LocalesSelector

## Path of the translation settings in project settings
var _settings_path: Dictionary = {
	"locales": "graph_dialogs/translation/locales",
	"default_locale": "graph_dialogs/translation/default_locale",
	"testing_locale": "graph_dialogs/translation/testing_locale",
	"csv_files_path": "graph_dialogs/translation/csv_files_path",
	"character_names_csv": "graph_dialogs/translation/character_names_csv",
	"translation_enabled": "graph_dialogs/translation/translation_enabled",
	"translation_with_csv": "graph_dialogs/translation/translation_with_csv",
	"translate_character_names": "graph_dialogs/translation/translate_character_names",
}

func _ready() -> void:
	# Set the default translation settings if they don't exist
	if not ProjectSettings.has_setting(_settings_path["translation_enabled"]):
		set_default_translation_settings()

	# Connect signals
	_use_translation_toggle.toggled.connect(_on_use_translation_toggled)
	_use_csv_files_toggle.toggled.connect(_on_use_csv_files_toggled)
	_translate_names_toggle.toggled.connect(_on_translate_names_toggled)

	locales_selector.locales_changed.connect(_on_locales_changed)
	csv_folder_field.folder_path_changed.connect(_on_csv_files_path_changed)
	char_names_csv_field.file_path_changed.connect(_on_char_names_csv_path_changed)

	# Load settings and set the values in the UI
	_use_translation_toggle.set_pressed(
		ProjectSettings.get_setting(_settings_path["translation_enabled"])
	)
	_use_csv_files_toggle.set_pressed(
		ProjectSettings.get_setting(_settings_path["translation_with_csv"])
	)
	_translate_names_toggle.set_pressed(
		ProjectSettings.get_setting(_settings_path["translate_character_names"])
	)
	csv_folder_field.set_value(
		ProjectSettings.get_setting(_settings_path["csv_files_path"])
	)
	char_names_csv_field.set_value(
		ProjectSettings.get_setting(_settings_path["character_names_csv"])
	)
	_on_use_translation_toggled(_use_translation_toggle.is_pressed())
	_on_use_csv_files_toggled(_use_csv_files_toggle.is_pressed())
	_on_translate_names_toggled(_translate_names_toggle.is_pressed())
	
	_set_locales_on_dropdown(default_locale_dropdown, true)
	_set_locales_on_dropdown(testing_locale_dropdown, false)
	locales_selector.set_locale_list()


## Set the editor language as the default locale
func set_default_translation_settings() -> void:
	ProjectSettings.set_setting(_settings_path["translation_enabled"], false)
	ProjectSettings.set_setting(_settings_path["translation_with_csv"], false)
	ProjectSettings.set_setting(_settings_path["translate_character_names"], false)
	ProjectSettings.set_setting(_settings_path["csv_files_path"], "")
	ProjectSettings.set_setting(_settings_path["character_names_csv"], "")

	# Set the editor locale as the default locale
	var settings = EditorInterface.get_editor_settings()
	var editor_lang = settings.get_setting("interface/editor/editor_language")
	ProjectSettings.set_setting(_settings_path["default_locale"], editor_lang)
	ProjectSettings.set_setting(_settings_path["testing_locale"], editor_lang)
	ProjectSettings.set_setting(_settings_path["locales"], [editor_lang])
	ProjectSettings.save()


## Load the locales available in the project on a dropdown
func _set_locales_on_dropdown(dropdown: OptionButton, default: bool) -> void:
	dropdown.clear()
	var locales = ProjectSettings.get_setting(_settings_path["locales"])

	if locales == null or locales.is_empty():
		dropdown.add_item("(no one)")
	
	for index in locales.size():
		dropdown.add_item(locales[index])
		if (default and locales[index] == ProjectSettings.get_setting(_settings_path["default_locale"])
			or not default and locales[index] == ProjectSettings.get_setting(_settings_path["testing_locale"])):
			dropdown.select(index)


#region === Handle UI ==========================================================

## Toggle the use of translations
func _on_use_translation_toggled(checked: bool) -> void:
	ProjectSettings.set_setting(_settings_path["translation_enabled"], checked)
	ProjectSettings.save()
	
	_use_csv_files_toggle.disabled = not checked
	_translate_names_toggle.disabled = not checked
	csv_folder_field.get_parent().visible = checked and _use_csv_files_toggle.is_pressed()
	char_names_csv_field.get_parent().visible = (checked and _translate_names_toggle.is_pressed()
		and _use_csv_files_toggle.is_pressed())


## Toggle the use of CSV files for translations
func _on_use_csv_files_toggled(checked: bool) -> void:
	ProjectSettings.set_setting(_settings_path["translation_with_csv"], checked)
	ProjectSettings.save()
	
	csv_folder_field.get_parent().visible = checked
	char_names_csv_field.get_parent().visible = checked and _translate_names_toggle.is_pressed()


## Toggle the translation of character names
func _on_translate_names_toggled(checked: bool) -> void:
	ProjectSettings.set_setting(_settings_path["translate_character_names"], checked)
	ProjectSettings.save()
	
	char_names_csv_field.get_parent().visible = _use_csv_files_toggle.is_pressed() and checked


## Select the default locale from the dropdown
func _on_default_locale_selected(index: int) -> void:
	ProjectSettings.set_setting(
		_settings_path["default_locale"],
		default_locale_dropdown.get_item_text(index)
	)
	ProjectSettings.save()
	default_locale_changed.emit()


## Select the testing locale from the dropdown
func _on_testing_locale_selected(index: int) -> void:
	ProjectSettings.set_setting(
		_settings_path["testing_locale"],
		testing_locale_dropdown.get_item_text(index)
	)
	ProjectSettings.save()
	testing_locale_changed.emit()


## Triggered when the locales change
func _on_locales_changed() -> void:
	# Update the dropdowns
	_set_locales_on_dropdown(default_locale_dropdown, true)
	_set_locales_on_dropdown(testing_locale_dropdown, false)
	
	# If the default or testing locales are removed, select the first locale
	var new_locales = ProjectSettings.get_setting(_settings_path["locales"])
	if not new_locales.has(ProjectSettings.get_setting(_settings_path["default_locale"])):
		_on_default_locale_selected(0)
	if not new_locales.has(ProjectSettings.get_setting(_settings_path["testing_locale"])):
		_on_testing_locale_selected(0)
	
	locales_changed.emit()


## Set the path to the CSV translation files
func _on_csv_files_path_changed(path: String) -> void:
	# Check if the path is empty or doesn't exist
	if path.is_empty() or not DirAccess.dir_exists_absolute(path):
		printerr("[Graph Dialogs] Please select a folder for CSV translation files.")
		return
	ProjectSettings.set_setting(_settings_path["csv_files_path"], path)
	ProjectSettings.save()


## Set the path to the CSV with character names translations
func _on_char_names_csv_path_changed(path: String) -> void:
	# Check if the path is empty
	if path.is_empty():
			printerr("[Graph Dialogs] Please select a CSV file for character names translation.")
			return
	# Check if the file is a CSV
	if not path.ends_with('.csv'):
		printerr("[Graph Dialogs] Character names file must be a CSV.")
		return
	# Check if the path is inside the CSV folder
	if not path.begins_with(ProjectSettings.get_setting(_settings_path["csv_files_path"])):
		printerr("[Graph Dialogs] Character names CSV file must be inside the CSV files folder.")
		return
	ProjectSettings.set_setting(_settings_path["character_names_csv"], path)
	ProjectSettings.save()


## Collect the translations from the CSV files
func _on_collect_translations_pressed() -> void:
	collect_translations(ProjectSettings.get_setting(_settings_path["csv_files_path"]))

#endregion

## Collect translation files from the CSV folder
func collect_translations(path: String) -> void:
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
		for locale in ProjectSettings.get_setting(_settings_path["locales"]):
			if file.split(".")[-2] == locale:
				valid_translation_files.append(file)
				break
	
	ProjectSettings.set_setting(
			'internationalization/locale/translations',
			PackedStringArray(valid_translation_files))
	ProjectSettings.save()


## Get the translation files from csv folder and its subfolders
func get_translation_files(path: String) -> Array:
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
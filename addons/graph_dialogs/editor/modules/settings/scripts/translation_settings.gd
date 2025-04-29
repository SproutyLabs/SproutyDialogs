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

## Default locale dropdown
@onready var default_locale_dropdown: OptionButton = %DefaultLocale/OptionButton
## Testing locale dropdown
@onready var testing_locale_dropdown: OptionButton = %TestingLocale/OptionButton
## Locales selector container
@onready var locales_selector: VBoxContainer = %LocalesSelector
## CSV folder path field
@onready var csv_folder_field: MarginContainer = %CSVFolderField
## Character names CSV path field
@onready var char_names_csv_field: MarginContainer = %CharNamesCSVField


func _ready() -> void:
	# Load the translation settings from the translation manager
	GraphDialogsTranslationManager.translation_settings = self
	GraphDialogsTranslationManager.load_translation_settings()

	# Connect signals
	locales_selector.connect("locales_changed", _on_locales_changed)
	csv_folder_field.connect("folder_path_changed", _on_csv_files_path_changed)
	char_names_csv_field.connect("file_path_changed", _on_char_names_csv_path_changed)

	# Load the locales on the dropdowns
	_set_locales_on_dropdown(default_locale_dropdown, true)
	_set_locales_on_dropdown(testing_locale_dropdown, false)


## Load the locales available in the project on a dropdown
func _set_locales_on_dropdown(dropdown: OptionButton, default: bool) -> void:
	dropdown.clear()
	var locales = GraphDialogsTranslationManager.locales
	
	if locales.is_empty():
		dropdown.add_item("(no one)")
	
	for index in locales.size():
		dropdown.add_item(locales[index])
		if default and locales[index] == GraphDialogsTranslationManager.default_locale \
				or not default and locales[index] == GraphDialogsTranslationManager.testing_locale:
			dropdown.select(index)


## Select the default locale from the dropdown
func _on_default_locale_selected(index: int) -> void:
	GraphDialogsTranslationManager.default_locale = default_locale_dropdown.get_item_text(index)
	GraphDialogsTranslationManager.save_translation_setting(
		"default_locale", GraphDialogsTranslationManager.default_locale
		)
	default_locale_changed.emit()


## Select the testing locale from the dropdown
func _on_testing_locale_selected(index: int) -> void:
	GraphDialogsTranslationManager.testing_locale = testing_locale_dropdown.get_item_text(index)
	GraphDialogsTranslationManager.save_translation_setting(
		"testing_locale", GraphDialogsTranslationManager.testing_locale
		)
	testing_locale_changed.emit()


## Triggered when the locales change
func _on_locales_changed() -> void:
	# Update the dropdowns
	_set_locales_on_dropdown(default_locale_dropdown, true)
	_set_locales_on_dropdown(testing_locale_dropdown, false)
	
	# If the default or testing locales are removed, select the first locale
	var new_locales = GraphDialogsTranslationManager.locales
	if not new_locales.has(GraphDialogsTranslationManager.default_locale):
		_on_default_locale_selected(0)
	if not new_locales.has(GraphDialogsTranslationManager.testing_locale):
		_on_testing_locale_selected(0)
	
	locales_changed.emit()


## Set the path to the CSV translation files
func _on_csv_files_path_changed(path: String) -> void:
	# Check if the path is empty or doesn't exist
	if path.is_empty() or not DirAccess.dir_exists_absolute(path):
		printerr("[Graph Dialogs] Please select a folder for CSV translation files.")
		return
	GraphDialogsTranslationManager.csv_files_path = path


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
	if not path.begins_with(GraphDialogsTranslationManager.csv_files_path):
		printerr("[Graph Dialogs] Character names CSV file must be inside the CSV files folder.")
		return
	GraphDialogsTranslationManager.char_names_csv_path = path


## Collect the translations from the CSV files
func _on_collect_translations_pressed() -> void:
	GraphDialogsTranslationManager.collect_translations()
@tool
extends HSplitContainer

## =============================================================================
## Translation settings
##
## This script handles the translation settings in settings tab. It allows to
## select the locales in the project, the default and testing locales, and the 
## folder where the CSV files are stored.
## =============================================================================

## Triggered when the locales change
signal locales_changed
## Triggered when the default locale changes
signal default_locale_changed
## Triggered when the testing locale changes
signal testing_locale_changed

## Default locale dropdown
@onready var default_locale_dropdown: OptionButton = $"%DefaultLocale" / OptionButton
## Testing locale dropdown
@onready var testing_locale_dropdown: OptionButton = $"%TestingLocale" / OptionButton
## Locales selector container
@onready var locales_selector: VBoxContainer = %LocalesSelector
## CSV folder field
@onready var csv_folder_field: MarginContainer = %CSVFolderField


func _init() -> void:
	# Load the translation settings from the translation manager
	GDialogsTranslationManager.load_translation_settings()
	GDialogsTranslationManager.translation_settings = self


func _ready() -> void:
	# Connect signals
	locales_selector.connect("locales_changed", _on_locales_changed)
	csv_folder_field.connect("folder_path_changed", _set_csv_files_path)
	
	# Load the csv files path
	if not GDialogsTranslationManager.csv_files_path.is_empty():
		csv_folder_field.set_value(GDialogsTranslationManager.csv_files_path)
	
	# Load the locales on the dropdowns
	_set_locales_on_dropdown(default_locale_dropdown, true)
	_set_locales_on_dropdown(testing_locale_dropdown, false)


## Load the locales available in the project on a dropdown
func _set_locales_on_dropdown(dropdown: OptionButton, default: bool) -> void:
	dropdown.clear()
	var locales = GDialogsTranslationManager.locales
	
	if locales.is_empty():
		dropdown.add_item("(no one)")
	
	for index in locales.size():
		dropdown.add_item(locales[index])
		if default and locales[index] == GDialogsTranslationManager.default_locale \
				or not default and locales[index] == GDialogsTranslationManager.testing_locale:
			dropdown.select(index)


## Select the default locale from the dropdown
func _on_default_locale_selected(index: int) -> void:
	GDialogsTranslationManager.default_locale = default_locale_dropdown.get_item_text(index)
	GDialogsTranslationManager.save_translation_settings()
	default_locale_changed.emit()


## Select the testing locale from the dropdown
func _on_testing_locale_selected(index: int) -> void:
	GDialogsTranslationManager.testing_locale = testing_locale_dropdown.get_item_text(index)
	GDialogsTranslationManager.save_translation_settings()
	testing_locale_changed.emit()


## Triggered when the locales change
func _on_locales_changed() -> void:
	# Update the dropdowns
	_set_locales_on_dropdown(default_locale_dropdown, true)
	_set_locales_on_dropdown(testing_locale_dropdown, false)
	
	# If the default or testing locales are removed, select the first locale
	var new_locales = GDialogsTranslationManager.locales
	if not new_locales.has(GDialogsTranslationManager.default_locale):
		_on_default_locale_selected(0)
	if not new_locales.has(GDialogsTranslationManager.testing_locale):
		_on_testing_locale_selected(0)
	
	locales_changed.emit()


## Set the path to the CSV translation files
func _set_csv_files_path(path: String) -> void:
	GDialogsTranslationManager.csv_files_path = path
	GDialogsTranslationManager.save_translation_settings()


## Collect the translations from the CSV files
func _on_collect_translations_pressed() -> void:
	GDialogsTranslationManager.collect_translations()

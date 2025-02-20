@tool
extends HSplitContainer

signal locales_changed

@onready var default_locale_dropdown : OptionButton = $"%DefaultLocale"/OptionButton
@onready var testing_locale_dropdown : OptionButton = $"%TestingLocale"/OptionButton
@onready var locales_selector : VBoxContainer = %LocalesSelector
@onready var csv_folder_field : MarginContainer = %CSVFolderField

func _init() -> void:
	GDialogsTranslationManager.load_translation_settings()

func _ready() -> void:
	locales_selector.connect("locales_changed", _on_locales_changed)
	csv_folder_field.connect("folder_path_changed", _set_csv_files_path)
	
	if not GDialogsTranslationManager.csv_files_path.is_empty():
		csv_folder_field.set_value(GDialogsTranslationManager.csv_files_path)
	
	_set_locales_on_dropdown(default_locale_dropdown)
	_set_locales_on_dropdown(testing_locale_dropdown)

func _set_locales_on_dropdown(dropdown : OptionButton) -> void:
	# Load the saved locales on a dropdown
	dropdown.clear()
	
	if GDialogsTranslationManager.locales.is_empty():
		dropdown.add_item("(no one)")
	
	for locale in GDialogsTranslationManager.locales:
		dropdown.add_item(locale)

func _on_default_locale_selected(index: int) -> void:
	# Select default locale from dropdown
	GDialogsTranslationManager.default_locale = default_locale_dropdown.get_item_text(index)
	GDialogsTranslationManager.save_translation_settings()

func _on_testing_locale_selected(index: int) -> void:
	# Select testing locale from dropdown
	GDialogsTranslationManager.testing_locale = testing_locale_dropdown.get_item_text(index)
	GDialogsTranslationManager.save_translation_settings()

func _on_locales_changed() -> void:
	# When the selected locales change, update the dropdowns
	_set_locales_on_dropdown(default_locale_dropdown)
	_set_locales_on_dropdown(testing_locale_dropdown)

func _set_csv_files_path(path : String) -> void:
	# Change the path to CSV translation files
	GDialogsTranslationManager.csv_files_path = path
	GDialogsTranslationManager.save_translation_settings()

func _on_collect_translations_pressed() -> void:
	# Collect the translation files from the CSV files folder
	GDialogsTranslationManager.collect_translations()

@tool
extends HSplitContainer

# -----------------------------------------------------------------------------
## Translation settings
##
## This script handles the translation settings in settings tab. It allows to
## select the locales in the project, the default and testing locales, and the 
## folder where the CSV files are stored.
# -----------------------------------------------------------------------------

## Emitted when the translation enabled setting changes
signal translation_enabled_changed(enabled: bool)
## Emitted when the use CSV files setting changes
signal use_csv_files_changed(enabled: bool)
## Emitted when the translate character names setting changes
signal translate_character_names_changed(enabled: bool)
## Emitted when the use CSV for names setting changes
signal use_csv_for_names_changed(enabled: bool)

## Emitted when the locales change
signal locales_changed
## Emitted when the default locale changes
signal default_locale_changed
## Emitted when the testing locale changes
signal testing_locale_changed

## Name of the character names CSV file
const CHAR_NAMES_CSV_NAME: String = "character_names.csv"

## Use translation toggle
@onready var _enable_translations_toggle: CheckButton = %EnableTranslationsToggle
## Use CSV files toggle
@onready var _use_csv_files_toggle: CheckButton = %UseCSVFilesToggle
## Translate character names toggle
@onready var _translate_names_toggle: CheckButton = %TranslateNamesToggle
## Use CSV for names toggle
@onready var _use_csv_for_names_toggle: CheckButton = %UseCSVForNamesToggle

## CSV folder path field
@onready var csv_folder_field: GraphDialogsFolderField = %CSVFolderField
## Character names CSV path field
@onready var char_names_csv_field: GraphDialogsFileField = %CharNamesCSVField
## CSV folder warning message
@onready var _csv_folder_warning: RichTextLabel = %CSVFolderWarning
## Character names CSV warning message
@onready var _char_csv_warning: RichTextLabel = %CharCSVWarning

## Default locale dropdown
@onready var default_locale_dropdown: OptionButton = %DefaultLocale/OptionButton
## Testing locale dropdown
@onready var testing_locale_dropdown: OptionButton = %TestingLocale/OptionButton
## Locales selector container
@onready var locales_selector: VBoxContainer = %LocalesSelector


func _ready() -> void:
	# Connect signals
	_enable_translations_toggle.toggled.connect(_on_use_translation_toggled)
	_use_csv_files_toggle.toggled.connect(_on_use_csv_files_toggled)
	_translate_names_toggle.toggled.connect(_on_translate_names_toggled)
	_use_csv_for_names_toggle.toggled.connect(_on_use_csv_for_names_toggled)

	locales_selector.locales_changed.connect(_on_locales_changed)
	csv_folder_field.folder_path_changed.connect(_on_csv_files_path_changed)
	char_names_csv_field.file_path_submitted.connect(_on_char_names_csv_path_changed)

	_csv_folder_warning.visible = false
	_char_csv_warning.visible = false

	await get_tree().process_frame # Wait a frame to ensure settings are loaded
	_load_settings()


## Load settings and set the values in the UI
func _load_settings() -> void:
	_enable_translations_toggle.button_pressed = \
		GraphDialogsSettings.get_setting("enable_translations")
	_use_csv_files_toggle.button_pressed = \
		GraphDialogsSettings.get_setting("use_csv")
	_translate_names_toggle.button_pressed = \
		GraphDialogsSettings.get_setting("translate_character_names")
	_use_csv_for_names_toggle.button_pressed = \
		GraphDialogsSettings.get_setting("use_csv_for_character_names")
	csv_folder_field.set_value(
		GraphDialogsSettings.get_setting("csv_translations_folder")
	)
	if GraphDialogsSettings.get_setting("character_names_csv") == -1:
		char_names_csv_field.set_value("") # No CSV set
	else:
		char_names_csv_field.set_value(ResourceUID.get_id_path(
				GraphDialogsSettings.get_setting("character_names_csv")
			)
		)
	_csv_folder_warning.visible = ( # Show warning if folder is invalid
		not DirAccess.dir_exists_absolute(csv_folder_field.get_value())
		and not csv_folder_field.get_value().is_empty()
	) # Show warning if character names CSV path is invalid
	_char_csv_warning.visible = not _valid_csv_path(char_names_csv_field.get_value())
	_set_locales_on_dropdown(default_locale_dropdown, true)
	_set_locales_on_dropdown(testing_locale_dropdown, false)
	locales_selector.set_locale_list()


#region === Locales ============================================================

## Load the locales available in the project on a dropdown
func _set_locales_on_dropdown(dropdown: OptionButton, default: bool) -> void:
	dropdown.clear()
	var locales = GraphDialogsSettings.get_setting("locales")

	if not default or locales == null or locales.is_empty():
		dropdown.add_item("(no one)")
	
	var default_locale = GraphDialogsSettings.get_setting("default_locale")
	var testing_locale = GraphDialogsSettings.get_setting("testing_locale")

	for index in locales.size():
		dropdown.add_item(locales[index])
		if (default and locales[index] == default_locale) or \
		   (not default and locales[index] == testing_locale):
			dropdown.select(index)


## Select the default locale from the dropdown
func _on_default_locale_selected(index: int) -> void:
	GraphDialogsSettings.set_setting(
		"default_locale",
		default_locale_dropdown.get_item_text(index)
	)
	default_locale_changed.emit()


## Select the testing locale from the dropdown
func _on_testing_locale_selected(index: int) -> void:
	var locale = testing_locale_dropdown.get_item_text(index)
	GraphDialogsSettings.set_setting(
		"testing_locale",
		locale if locale != "(no one)" else ""
	)
	testing_locale_changed.emit()


## Triggered when the locales change
func _on_locales_changed() -> void:
	# Update the dropdowns
	_set_locales_on_dropdown(default_locale_dropdown, true)
	_set_locales_on_dropdown(testing_locale_dropdown, false)
	
	# If the default or testing locales are removed, select the first locale
	var new_locales = GraphDialogsSettings.get_setting("locales")
	if not new_locales.has(GraphDialogsSettings.get_setting("default_locale")):
		_on_default_locale_selected(0)
	if not new_locales.has(GraphDialogsSettings.get_setting("testing_locale")):
		_on_testing_locale_selected(0)
	
	locales_changed.emit()

#endregion

#region === Translation Settings ===============================================

## Toggle the use of translations
func _on_use_translation_toggled(checked: bool) -> void:
	GraphDialogsSettings.set_setting("enable_translations", checked)
	
	_use_csv_files_toggle.disabled = not checked
	_translate_names_toggle.disabled = not checked
	_use_csv_for_names_toggle.disabled = not checked
	csv_folder_field.disable_field(not (checked and _use_csv_files_toggle.is_pressed()))
	char_names_csv_field.disable_field(
		not (checked and _translate_names_toggle.is_pressed())
		and _use_csv_files_toggle.is_pressed()
	)
	# Set warnings visibility
	_csv_folder_warning.visible = (checked
			and _use_csv_files_toggle.is_pressed()
			and (csv_folder_field.get_value().is_empty()
			or not DirAccess.dir_exists_absolute(csv_folder_field.get_value()))
	)
	_char_csv_warning.visible = (checked
			and _translate_names_toggle.is_pressed()
			and _use_csv_for_names_toggle.is_pressed() \
			and not _valid_csv_path(char_names_csv_field.get_value())
	)
	translation_enabled_changed.emit(checked)
	translate_character_names_changed.emit(
		checked and _translate_names_toggle.is_pressed()
	)


## Toggle the use of CSV files for translations
func _on_use_csv_files_toggled(checked: bool) -> void:
	GraphDialogsSettings.set_setting("use_csv", checked)

	csv_folder_field.disable_field(not (checked and _enable_translations_toggle.is_pressed()))
	csv_folder_field.get_parent().visible = checked
	char_names_csv_field.get_parent().visible = (checked
			and _translate_names_toggle.is_pressed()
			and _use_csv_for_names_toggle.is_pressed()
	)
	_use_csv_for_names_toggle.disabled = not (checked and _enable_translations_toggle.is_pressed())
	_use_csv_for_names_toggle.visible = checked and _translate_names_toggle.is_pressed()
	_csv_folder_warning.visible = (checked
			and (csv_folder_field.get_value().is_empty()
			or not DirAccess.dir_exists_absolute(csv_folder_field.get_value()))
	)
	use_csv_files_changed.emit(checked)


## Toggle the translation of character names
func _on_translate_names_toggled(checked: bool) -> void:
	GraphDialogsSettings.set_setting("translate_character_names", checked)
	
	_use_csv_for_names_toggle.disabled = not (checked and _enable_translations_toggle.is_pressed())
	_use_csv_for_names_toggle.visible = checked and _use_csv_files_toggle.is_pressed()
	char_names_csv_field.get_parent().visible = checked and _use_csv_for_names_toggle.is_pressed()
	_char_csv_warning.visible = (checked
			and _use_csv_for_names_toggle.is_pressed()
			and not _valid_csv_path(char_names_csv_field.get_value())
	)
	translate_character_names_changed.emit(checked)


## Toggle the use of CSV for character names translations
func _on_use_csv_for_names_toggled(checked: bool) -> void:
	GraphDialogsSettings.set_setting("use_csv_for_character_names", checked)
	
	if checked and char_names_csv_field.get_value().is_empty():
		_new_character_names_csv() # Create a new CSV template if the path is empty
	
	char_names_csv_field.get_parent().visible = checked
	_char_csv_warning.visible = checked and not _valid_csv_path(char_names_csv_field.get_value())
	use_csv_for_names_changed.emit(checked)


## Set the path to the CSV translation files
func _on_csv_files_path_changed(path: String) -> void:
	# Check if the path is empty or doesn't exist
	if path.is_empty() or not DirAccess.dir_exists_absolute(path):
		_csv_folder_warning.visible = true
		return
	_csv_folder_warning.visible = false
	GraphDialogsSettings.set_setting("csv_translations_folder", path)


## Set the path to the CSV with character names translations
func _on_char_names_csv_path_changed(path: String) -> void:
	if not _valid_csv_path(path):
		_char_csv_warning.visible = true
		return
	_char_csv_warning.visible = false
	GraphDialogsSettings.set_setting("character_names_csv",
			ResourceSaver.get_resource_id_for_path(path))


## Create a new CSV template file for character names
func _new_character_names_csv() -> void:
	var path = GraphDialogsSettings.get_setting(
			"csv_translations_folder") + "/" + CHAR_NAMES_CSV_NAME

	if not FileAccess.file_exists(path): # If the file doesn't exist, create a new one
		path = GraphDialogsCSVFileManager.new_csv_template_file(CHAR_NAMES_CSV_NAME)
	
	_char_csv_warning.visible = false
	char_names_csv_field.set_value(path)
	GraphDialogsSettings.set_setting("character_names_csv",
			ResourceSaver.get_resource_id_for_path(path))


## Check if the CSV path is valid
func _valid_csv_path(path: String) -> bool:
	# Check if the path is empty or doesn't exist
	if not GraphDialogsFileUtils.check_valid_extension(path, ["*.csv"]):
		return false
	if not path.get_base_dir() == GraphDialogsSettings.get_setting("csv_translations_folder"):
		return false
	return true


## Collect the translations from the CSV files
func _on_collect_translations_pressed() -> void:
	GraphDialogsFileUtils.collect_translations()

#endregion

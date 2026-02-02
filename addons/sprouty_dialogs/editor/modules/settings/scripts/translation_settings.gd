@tool
extends HSplitContainer

# -----------------------------------------------------------------------------
# Translation settings
# -----------------------------------------------------------------------------
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
## Fallback to resource if key not found toggle
@onready var _fallback_to_resource_toggle: CheckButton = %FallbackToResourceToggle
## Translate character names toggle
@onready var _translate_names_toggle: CheckButton = %TranslateNamesToggle
## Use CSV for names toggle
@onready var _use_csv_for_names_toggle: CheckButton = %UseCSVForNamesToggle

## CSV folder path field
@onready var csv_folder_field: EditorSproutyDialogsFileField = %CSVFolderField
## Character names CSV path field
@onready var char_names_csv_field: EditorSproutyDialogsFileField = %CharNamesCSVField
## CSV folder warning message
@onready var _csv_folder_warning: RichTextLabel = %CSVFolderWarning
## Character names CSV warning message
@onready var _char_csv_warning: RichTextLabel = %CharCSVWarning

## Collect translations button
@onready var _collect_translations_button: Button = %CollectTranslationsButton

## Default locale dropdown
@onready var default_locale_dropdown: OptionButton = %DefaultLocale/OptionButton
## Testing locale dropdown
@onready var testing_locale_dropdown: OptionButton = %TestingLocale/OptionButton
## Locales selector container
@onready var locales_selector: EditorSproutyDialogsLocalesSelector = %LocalesSelector


func _ready() -> void:
	# Connect signals
	_collect_translations_button.pressed.connect(_on_collect_translations_pressed)
	_enable_translations_toggle.toggled.connect(_on_use_translation_toggled)
	_use_csv_files_toggle.toggled.connect(_on_use_csv_files_toggled)
	_fallback_to_resource_toggle.toggled.connect(_on_fallback_to_resource_toggled)
	_translate_names_toggle.toggled.connect(_on_translate_names_toggled)
	_use_csv_for_names_toggle.toggled.connect(_on_use_csv_for_names_toggled)

	locales_selector.locales_changed.connect(_on_locales_changed)
	csv_folder_field.path_changed.connect(_on_csv_files_path_changed)
	char_names_csv_field.path_changed.connect(_on_char_names_csv_path_changed)

	_csv_folder_warning.visible = false
	_char_csv_warning.visible = false

	await get_tree().process_frame # Wait a frame to ensure settings are loaded
	_load_settings()


## Update settings when the panel is selected
func update_settings() -> void:
	if _char_csv_warning.visible: # Reset path
		char_names_csv_field.set_value(_get_saved_setting("character_names_csv"))
		_show_reset_button(char_names_csv_field, "character_names_csv")
		_char_csv_warning.hide()
	
	if _csv_folder_warning.visible: # Reset path
		csv_folder_field.set_value(_get_saved_setting("csv_translations_folder"))
		_show_reset_button(csv_folder_field, "csv_translations_folder")
		_csv_folder_warning.hide()
		_collect_translations_button.disabled = not (
			_enable_translations_toggle.is_pressed()
			and _use_csv_files_toggle.is_pressed()
		)


## Load settings and set the values in the UI
func _load_settings() -> void:
	_enable_translations_toggle.button_pressed = \
		SproutyDialogsSettingsManager.get_setting("enable_translations")
	_use_csv_files_toggle.button_pressed = \
		SproutyDialogsSettingsManager.get_setting("use_csv_files")
	_fallback_to_resource_toggle.button_pressed = \
		SproutyDialogsSettingsManager.get_setting("fallback_to_resource")
	_translate_names_toggle.button_pressed = \
		SproutyDialogsSettingsManager.get_setting("translate_character_names")
	_use_csv_for_names_toggle.button_pressed = \
		SproutyDialogsSettingsManager.get_setting("use_csv_for_character_names")
	csv_folder_field.set_value(
		SproutyDialogsSettingsManager.get_setting("csv_translations_folder")
	)
	var char_names_csv = SproutyDialogsSettingsManager.get_setting("character_names_csv")
	if not SproutyDialogsFileUtils.check_valid_uid_path(char_names_csv):
		if char_names_csv != -1:
			printerr("[Sprouty Dialogs] Character names CSV file not found." \
					+" Check that the character names CSV is set in Settings > Translation" \
					+" plugin tab, and that the CSV file exists.")
		char_names_csv_field.set_value("") # No CSV set
	else:
		char_names_csv_field.set_value(ResourceUID.get_id_path(char_names_csv))
	
	_set_reset_button(csv_folder_field, "csv_translations_folder")
	_set_reset_button(_fallback_to_resource_toggle, "fallback_to_resource")
	_set_reset_button(_use_csv_for_names_toggle, "use_csv_for_character_names")
	_set_reset_button(char_names_csv_field, "character_names_csv")

	_update_csv_folder_warning()
	_update_character_csv_warning()
	_set_locales_on_dropdowns()
	locales_selector.set_locale_list()


## Setup the reset button of a field
func _set_reset_button(field: Control, setting_name: String) -> void:
	var default_value = SproutyDialogsSettingsManager.get_default_setting(setting_name)
	var reset_button = field.get_parent().get_child(1)

	if field is EditorSproutyDialogsFileField:
		# Use the previous saved settings instead of default
		reset_button.pressed.connect(func():
			field.set_value(_get_saved_setting(setting_name))
			reset_button.hide()

			if setting_name == "csv_translations_folder":
				_update_csv_folder_warning()
			if setting_name == "character_names_csv":
				_update_character_csv_warning()
		)
		reset_button.visible = field.get_value() != _get_saved_setting(setting_name)
	
	elif field is CheckButton:
		reset_button.pressed.connect(func():
			SproutyDialogsSettingsManager.reset_setting(setting_name)
			field.set_pressed_no_signal(default_value)
			reset_button.hide()
		)
		reset_button.visible = field.button_pressed != default_value
	
	elif field is OptionButton:
		reset_button.pressed.connect(func():
			field.select(0)
			reset_button.hide()

			if setting_name == "default_locale":
				_on_default_locale_selected(0)
			if setting_name == "testing_locale":
				_on_testing_locale_selected(0)
		)
		reset_button.visible = field.selected != 0


## Show the reset button of a field
func _show_reset_button(field: Control, setting_name: String) -> void:
	var default_value = SproutyDialogsSettingsManager.get_default_setting(setting_name)
	var reset_button = field.get_parent().get_child(1)

	if field is EditorSproutyDialogsFileField:
		reset_button.visible = field.get_value() != _get_saved_setting(setting_name)
	
	elif field is CheckButton:
		reset_button.visible = field.button_pressed != default_value
	
	elif field is OptionButton:
		reset_button.visible = field.selected != 0


## Get the previous saved setting value
func _get_saved_setting(setting_name: String) -> Variant:
	var setting_value = SproutyDialogsSettingsManager.get_setting(setting_name)
	if setting_value is int:
		if ResourceUID.has_id(setting_value):
			return ResourceUID.get_id_path(setting_value)
		else:
			return ""
	else:
		return setting_value


#region === Locales ============================================================

## Load the locales available in the project on the default and testing locale dropdowns
func _set_locales_on_dropdowns() -> void:
	var locales = SproutyDialogsSettingsManager.get_setting("locales")
	var default_locale = SproutyDialogsSettingsManager.get_setting("default_locale")
	var testing_locale = SproutyDialogsSettingsManager.get_setting("testing_locale")

	default_locale_dropdown.clear()
	testing_locale_dropdown.clear()

	if locales == null or locales.is_empty():
		default_locale_dropdown.add_item("(no one)")
	testing_locale_dropdown.add_item("(no one)")
	
	for index in locales.size():
		default_locale_dropdown.add_item(locales[index])
		testing_locale_dropdown.add_item(locales[index])
		# Select the current default and testing locales
		if locales[index] == default_locale:
			default_locale_dropdown.select(index)
		if locales[index] == testing_locale:
			testing_locale_dropdown.select(index + 1) # For the "(no one)" item
	
	_set_reset_button(default_locale_dropdown, "default_locale")
	_set_reset_button(testing_locale_dropdown, "testing_locale")


## Select the default locale from the dropdown
func _on_default_locale_selected(index: int, no_emit: bool = false) -> void:
	_show_reset_button(default_locale_dropdown, "default_locale")
	var locale = default_locale_dropdown.get_item_text(index)
	SproutyDialogsSettingsManager.set_setting(
		"default_locale",
		locale if locale != "(no one)" else ""
	)
	if not no_emit:
		default_locale_changed.emit()


## Select the testing locale from the dropdown
func _on_testing_locale_selected(index: int) -> void:
	_show_reset_button(testing_locale_dropdown, "testing_locale")
	var locale = testing_locale_dropdown.get_item_text(index)
	SproutyDialogsSettingsManager.set_setting(
		"testing_locale",
		locale if locale != "(no one)" else ""
	)
	testing_locale_changed.emit()


## Triggered when the locales change
func _on_locales_changed() -> void:
	_set_locales_on_dropdowns() # Refresh the dropdowns
	
	# If the default or testing locales are removed, select the first locale
	var new_locales = SproutyDialogsSettingsManager.get_setting("locales")
	if not new_locales.has(SproutyDialogsSettingsManager.get_setting("default_locale")):
		_on_default_locale_selected(0, true)
	if not new_locales.has(SproutyDialogsSettingsManager.get_setting("testing_locale")):
		_on_testing_locale_selected(0)
	
	locales_changed.emit()

#endregion

#region === Translation Settings ===============================================

## Toggle the use of translations
func _on_use_translation_toggled(checked: bool) -> void:
	SproutyDialogsSettingsManager.set_setting("enable_translations", checked)
	
	_use_csv_files_toggle.disabled = not checked
	_translate_names_toggle.disabled = not checked
	_use_csv_for_names_toggle.disabled = not checked
	_fallback_to_resource_toggle.disabled = not checked
	csv_folder_field.disable_field(not (checked and _use_csv_files_toggle.is_pressed()))
	char_names_csv_field.disable_field(
		not (checked and _translate_names_toggle.is_pressed())
		and _use_csv_files_toggle.is_pressed()
	)
	_collect_translations_button.disabled = not (checked
			and _use_csv_files_toggle.is_pressed()
			and not _csv_folder_warning.visible
	)
	# Set warnings visibility
	_update_csv_folder_warning()
	_update_character_csv_warning()

	translation_enabled_changed.emit(checked)
	translate_character_names_changed.emit(
		checked and _translate_names_toggle.is_pressed()
	)

#region --- CSV Settings -------------------------------------------------------

## Toggle the use of CSV files for translations
func _on_use_csv_files_toggled(checked: bool) -> void:
	SproutyDialogsSettingsManager.set_setting("use_csv_files", checked)
	
	csv_folder_field.disable_field(not (checked and _enable_translations_toggle.is_pressed()))
	csv_folder_field.get_parent().visible = checked

	_fallback_to_resource_toggle.disabled = not (checked and _enable_translations_toggle.is_pressed())
	_fallback_to_resource_toggle.get_parent().visible = checked

	_collect_translations_button.disabled = not (checked
			and _enable_translations_toggle.is_pressed()
			and not _csv_folder_warning.visible)

	char_names_csv_field.get_parent().visible = (checked
			and _translate_names_toggle.is_pressed()
			and _use_csv_for_names_toggle.is_pressed()
	)
	_use_csv_for_names_toggle.disabled = not (checked and _enable_translations_toggle.is_pressed())
	_use_csv_for_names_toggle.get_parent().visible = checked and _translate_names_toggle.is_pressed()
	_update_csv_folder_warning()
	use_csv_files_changed.emit(checked)


## Toggle the fallback to resource dialogs if key not found in CSV
func _on_fallback_to_resource_toggled(checked: bool) -> void:
	SproutyDialogsSettingsManager.set_setting("fallback_to_resource", checked)
	_show_reset_button(_fallback_to_resource_toggle, "fallback_to_resource")


## Set the path to the CSV translation files
func _on_csv_files_path_changed(path: String) -> void:
	_show_reset_button(csv_folder_field, "csv_translations_folder")
	# Check if the path is empty or doesn't exist
	if path.is_empty() or not DirAccess.dir_exists_absolute(path):
		_csv_folder_warning.visible = true
		_collect_translations_button.disabled = true
		return
	_csv_folder_warning.visible = false
	_collect_translations_button.disabled = not (_enable_translations_toggle.is_pressed()
			and _use_csv_files_toggle.is_pressed())
	SproutyDialogsSettingsManager.set_setting("csv_translations_folder", path)


## Check if the CSV path is valid
func _valid_csv_path(path: String) -> bool:
	# Check if the path is empty or doesn't exist
	if not SproutyDialogsFileUtils.check_valid_extension(path, ["*.csv"]):
		return false
	if not path.begins_with(SproutyDialogsSettingsManager.get_setting("csv_translations_folder")):
		return false
	return true


## Collect the translations from the CSV files
func _on_collect_translations_pressed() -> void:
	SproutyDialogsTranslationManager.collect_translations()


#endregion

#region --- Character Names Settings -------------------------------------------

## Toggle the translation of character names
func _on_translate_names_toggled(checked: bool) -> void:
	SproutyDialogsSettingsManager.set_setting("translate_character_names", checked)
	
	_use_csv_for_names_toggle.disabled = not (checked and _enable_translations_toggle.is_pressed())
	_use_csv_for_names_toggle.get_parent().visible = checked and _use_csv_files_toggle.is_pressed()
	char_names_csv_field.get_parent().visible = (checked
			and _use_csv_for_names_toggle.is_pressed()
			and _use_csv_files_toggle.is_pressed()
		)
	_update_character_csv_warning()

	translate_character_names_changed.emit(checked)


## Toggle the use of CSV for character names translations
func _on_use_csv_for_names_toggled(checked: bool) -> void:
	SproutyDialogsSettingsManager.set_setting("use_csv_for_character_names", checked)
	_show_reset_button(_use_csv_for_names_toggle, "use_csv_for_character_names")
	
	if checked and char_names_csv_field.get_value().is_empty():
		_new_character_names_csv() # Create a new CSV template if the path is empty
	
	char_names_csv_field.get_parent().visible = checked
	_update_character_csv_warning()

	use_csv_for_names_changed.emit(checked)


## Set the path to the CSV with character names translations
func _on_char_names_csv_path_changed(path: String) -> void:
	_show_reset_button(char_names_csv_field, "character_names_csv")
	if not _valid_csv_path(path):
		_char_csv_warning.visible = true
		return
	_char_csv_warning.visible = false
	SproutyDialogsSettingsManager.set_setting("character_names_csv",
			ResourceSaver.get_resource_id_for_path(path, true))
	
	SproutyDialogsTranslationManager.collect_translations()
	# Refresh the filesystem to ensure the translations are imported
	var editor_interface = Engine.get_singleton("EditorInterface")
	editor_interface.get_resource_filesystem().scan()
	await editor_interface.get_resource_filesystem().resources_reimported


## Create a new CSV template file for character names
func _new_character_names_csv() -> void:
	var csv_folder = SproutyDialogsSettingsManager.get_setting("csv_translations_folder")
	if csv_folder.is_empty() or not DirAccess.dir_exists_absolute(csv_folder):
		_csv_folder_warning.visible = true
		return
	var path = SproutyDialogsSettingsManager.get_setting(
			"csv_translations_folder") + "/" + CHAR_NAMES_CSV_NAME

	if not FileAccess.file_exists(path): # If the file doesn't exist, create a new one
		path = SproutyDialogsCSVFileManager.new_csv_template_file(CHAR_NAMES_CSV_NAME)
	
	_char_csv_warning.visible = false
	char_names_csv_field.set_value(path)
	SproutyDialogsSettingsManager.set_setting("character_names_csv",
			ResourceSaver.get_resource_id_for_path(path, true))

#endregion

#endregion

#region === Warnings ==========================================================

## Update the character names CSV warning visibility
func _update_character_csv_warning() -> void:
	_char_csv_warning.visible = (not _valid_csv_path(char_names_csv_field.get_value())
			and _use_csv_for_names_toggle.is_pressed()
			and _translate_names_toggle.is_pressed()
			and _use_csv_files_toggle.is_pressed()
			and _enable_translations_toggle.is_pressed())

## Update the CSV folder warning visibility
func _update_csv_folder_warning() -> void:
	_csv_folder_warning.visible = (not DirAccess.dir_exists_absolute(csv_folder_field.get_value())
			and not csv_folder_field.get_value().is_empty()
			and _use_csv_files_toggle.is_pressed()
			and _enable_translations_toggle.is_pressed())

#endregion
@tool
class_name EditorSproutyDialogsLocalesSelector
extends VBoxContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs Locales Selector Component
# -----------------------------------------------------------------------------
## Component that contains a list of locale fields to select the locales
## to be used in the translations of the dialog system.
# -----------------------------------------------------------------------------

## Triggered when the locales are changed.
signal locales_changed

## Container with the locales fields.
@onready var _locales_container: VBoxContainer = %LocalesContainer
## Confirm save locales dialog
@onready var _confirm_panel: AcceptDialog = $ConfirmSaveLocales

## Locale field template.
var _locale_field := preload("res://addons/sprouty_dialogs/editor/modules/settings/components/locale_field.tscn")
## Current locales for save.
var _current_locales: Array = []


func _ready() -> void:
	# Set the confirm save dialog actions
	_confirm_panel.get_ok_button().hide()
	_confirm_panel.add_button('Save Changes', true, 'save_changes')
	_confirm_panel.add_button('Discard Changes', true, 'discard_changes')
	_confirm_panel.add_cancel_button('Cancel')
	$SaveButton.icon = get_theme_icon("Save", "EditorIcons")


## Set the locale list loading the saved locales.
func set_locale_list() -> void:
	for child in _locales_container.get_children():
		if child is MarginContainer:
			child.queue_free()
	
	var locales = SproutyDialogsSettingsManager.get_setting("locales")
	
	if locales == null or locales.is_empty():
		$"%LocalesContainer" / Label.visible = true
		return
	
	for locale in locales:
		# Load saved locales in the list
		var new_locale = _new_locale()
		if not new_locale.is_node_ready():
			await new_locale.ready
		new_locale.load_locale(locale)


## Add a new locale field to the list.
func _new_locale() -> EditorSproutyDialogsLocaleField:
	var new_locale = _locale_field.instantiate()
	new_locale.locale_removed.connect(_on_locale_removed)
	new_locale.locale_modified.connect(_on_locales_modified)
	_locales_container.add_child(new_locale)
	$"%LocalesContainer" / Label.visible = false
	return new_locale


## Add a new locale field when the add button is pressed.
func _on_add_locale_pressed() -> void:
	_new_locale()
	_on_locales_modified()


## When a locale is removed from the list, update the list.
func _on_locale_removed(locale_code: String) -> void:
	if _locales_container.get_child_count() == 0:
		$"%LocalesContainer" / Label.visible = true
	_on_locales_modified()


## Save the locales selected.
func _save_locales() -> void:
	SproutyDialogsSettingsManager.set_setting("locales", _current_locales)
	locales_changed.emit()
	_current_locales = []
	$SaveButton.text = "Save Locales"
	print("[Sprouty Dialogs] Locales saved.")


## When the save locales button is pressed, save the locales selected.
func _on_save_locales_pressed() -> void:
	# Collect locales selected and save changes
	for field in _locales_container.get_children():
		if not field is MarginContainer: continue
		var locale = field.get_locale_code()
		if locale == "":
			printerr("[Sprouty Dialogs] Cannot save locales, please fix the issues.")
			return
		_current_locales.append(locale)
	
	# If a locale has been removed, show confirmation alert
	for locale in SproutyDialogsSettingsManager.get_setting("locales"):
		if not _current_locales.has(locale):
			_confirm_panel.popup_centered()
			return
	
	_save_locales()


## Set the confirm save dialog actions
func _on_confirm_save_action(action) -> void:
	_confirm_panel.hide()
	
	match action:
		"save_changes":
			_save_locales()
		"discard_changes":
			$SaveButton.text = "Save Locales"
			_current_locales = []
			set_locale_list()


## When save is canceled, clear the locales for save.
func _on_confirm_save_canceled() -> void:
	_current_locales = []


## When the locales are modified, indicate unsaved changes.
func _on_locales_modified() -> void:
	$SaveButton.text = "Save Locales (*)"

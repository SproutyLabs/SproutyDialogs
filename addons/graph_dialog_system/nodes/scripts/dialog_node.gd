@tool
extends BaseNode

@onready var char_selector : OptionButton = %CharacterSelect
@onready var default_text_box : HBoxContainer = %DefaultTextBox
@onready var translation_boxes : VBoxContainer = %Translations

@onready var char_key : String = char_selector.get_item_text(char_selector.selected)

var default_locale : String = ""

func _ready():
	super()
	_set_translation_text_boxes()
	GDialogsTranslationManager.translation_settings.connect(
			"locales_changed", _on_locales_changed
		)
	GDialogsTranslationManager.translation_settings.connect(
			"default_locale_changed", _on_locales_changed
		)

func get_data() -> Dictionary:
	# Get node data on dict
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type_id" : node_type_id,
		"node_index" : node_index,
		"char_key" : "",
		"dialog_key" : get_dialog_key(),
		"to_node" : [connections[0]["to_node"].to_snake_case()]
				if connections.size() > 0 else ["END"],
		"offset" : {
			"x" : position_offset.x,
			"y" : position_offset.y
		}
	}
	return dict

func set_data(dict : Dictionary) -> void:
	# Set node data from dict
	node_type_id = dict["node_type_id"]
	node_index = dict["node_index"]
	char_key = dict["char_key"]
	to_node = dict["to_node"]
	position_offset.x = dict["offset"]["x"]
	position_offset.y = dict["offset"]["y"]

func load_dialogs(dialogs : Dictionary) -> void:
	# Load dialog and translations from CSV data
	default_text_box.set_text(dialogs[default_locale])
	translation_boxes.load_translations_text(dialogs)

func get_dialogs_text() -> Dictionary:
	# Return the dialog text and its translations
	var dialogs = {}
	dialogs[default_locale] = default_text_box.get_text()
	dialogs.merge(translation_boxes.get_translations_text())
	return dialogs

func get_dialog_key() -> String:
	# Create the dialog key for CSV reference
	if start_node != null: return get_start_id() + "_" + str(node_index)
	else: return "NODE_" + str(node_index)

func _set_translation_text_boxes() -> void:
	# Set text boxes for translation
	default_locale = GDialogsTranslationManager.default_locale
	%DefaultLocaleLabel.text = "(" + default_locale + ")"
	default_text_box.set_text("")
	translation_boxes.set_translation_boxes(
			GDialogsTranslationManager.locales.filter(
				func(locale): return locale != default_locale
			)
		)

func _on_locales_changed() -> void:
	# Update the locale text boxes
	var dialogs = get_dialogs_text()
	_set_translation_text_boxes()
	load_dialogs(dialogs)

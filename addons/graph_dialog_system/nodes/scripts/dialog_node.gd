@tool
extends BaseNode

@onready var char_selector : OptionButton = %CharacterSelect
@onready var default_text_box : HBoxContainer = %DefaultTextBox
@onready var translation_boxes : VBoxContainer = %Translations

@onready var char_key : String = char_selector.get_item_text(char_selector.selected)
@onready var dialog_key : String = ""

func _ready():
	super()
	_set_dialog_translations()
	dialog_key = _create_dialog_key()

func get_data() -> Dictionary:
	# Get node data on dict
	var dict := {}
	var connections: Array = get_parent().get_node_connections(name)
	
	dict[name.to_snake_case()] = {
		"node_type_id" : node_type_id,
		"char_key" : "",
		"dialog_key" : "",
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
	char_key = dict["char_key"]
	dialog_key = dict["dialog_key"]
	to_node = dict["to_node"]
	position_offset.x = dict["offset"]["x"]
	position_offset.y = dict["offset"]["y"]

func load_data(dict : Dictionary) -> void:
	set_data(dict)
	# TODO: Load character selected
	# TODO: Load dialog and translations from csv
	pass

func _create_dialog_key() -> String:
	# Create the dialog key for CSV reference
	return get_start_id() + "_" + str(graph_editor.nodes_count[node_type_id])

func _set_dialog_translations() -> void:
	# Set text boxes for translation
	%DefaultLocaleLabel.text = "(" + GDialogsTranslationManager.default_locale + ")"
	translation_boxes.set_translation_boxes(GDialogsTranslationManager.locales)

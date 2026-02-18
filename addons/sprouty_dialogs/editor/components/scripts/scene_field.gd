@tool
class_name EditorSproutyDialogsSceneField
extends HBoxContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs Scene Field Component
# -----------------------------------------------------------------------------
## Component that allows to select a scene and show its path in the field.
## It has buttons to create a new scene of a given type and go to edit the scene.
# -----------------------------------------------------------------------------

## Emitted when the scene is changed
signal scene_path_changed(path: String)

## Scene types enum
enum SceneType {DIALOG_BOX, PORTRAIT}

## Scene type to load
@export var scene_type: SceneType

## Field to show the current file path.
@onready var _path_field: LineEdit = $PathField
## New scene file dialog
@onready var _new_scene_dialog: FileDialog = $NewSceneDialog

## File type to load the last used path
var _recent_file_type: String
## File dialog title
var _dialog_title: String
## New scene file default name
var _new_file_default: String
## New scene type identifier
var _new_scene_type: String

## Scene resource picker
var scene_picker: EditorSproutyDialogsResourcePicker


func _ready() -> void:
	# Setup buttons
	$GoToSceneButton.pressed.connect(_on_go_to_scene_button_pressed)
	$NewSceneButton.pressed.connect(_on_new_scene_button_pressed)
	$GoToSceneButton.icon = get_theme_icon("PackedScene", "EditorIcons")
	$NewSceneButton.icon = get_theme_icon("Add", "EditorIcons")
	$GoToSceneButton.hide()
	$NewSceneButton.show()

	# Setup new scene file dialog
	_new_scene_dialog.file_selected.connect(_new_scene)
	_new_scene_dialog.filters = ["*.tscn"]

	# Add the resource picker to open scenes
	scene_picker = EditorSproutyDialogsResourcePicker.new()
	scene_picker.add_clear_button = true
	add_child(scene_picker)
	scene_picker.resource_picked.connect(_on_scene_selected)
	scene_picker.clear_pressed.connect(clear_path)

	set_scene_type(scene_type)


## Set the resource type to load
func set_scene_type(type: SceneType) -> void:
	scene_type = type
	match type:
		SceneType.DIALOG_BOX:
			scene_picker.set_resource_type(scene_picker.ResourceType.DIALOG_BOX)
			_dialog_title = "New Dialog Box Scene"
			_new_file_default = "new_dialog_box.tscn"
			_recent_file_type = "dialog_box_files"
			_new_scene_type = "dialog_box"
		SceneType.PORTRAIT:
			scene_picker.set_resource_type(scene_picker.ResourceType.PORTRAIT_SCENE)
			_dialog_title = "New Portrait Scene"
			_new_file_default = "new_portrait.tscn"
			_recent_file_type = "portrait_files"
			_new_scene_type = "portrait_scene"


## Returns the UID of the selected scene
func get_scene_uid() -> int:
	var path = get_scene_path()
	if path == "":
		return -1
	return ResourceSaver.get_resource_id_for_path(path, true)


## Returns the current scene path in the field.
func get_scene_path() -> String:
	if not _check_valid_scene(_path_field.text):
		return ""
	return _path_field.text


## Set the scene path in the field
func set_scene_path(path: String) -> void:
	if not _check_valid_scene(path):
		_path_field.text = ""
	else:
		_path_field.text = path


## Clear the current value of the field.
func clear_path() -> void:
	set_scene_path("")
	scene_path_changed.emit("")


## Set path of file or folder selected in the file dialog.
func _on_scene_selected(res: Resource) -> void:
	SproutyDialogsFileUtils.set_recent_file_path(_recent_file_type, res.resource_path)
	set_scene_path(res.resource_path)
	scene_path_changed.emit(res.resource_path)


## Handle when the go to scene button is pressed
func _on_go_to_scene_button_pressed() -> void:
	SproutyDialogsFileUtils.open_scene_in_editor(get_scene_path(), get_tree())


## Create a new scene and open it in the editor
func _on_new_scene_button_pressed() -> void:
	_new_scene_dialog.set_current_dir(SproutyDialogsFileUtils.get_recent_file_path(_recent_file_type))
	_new_scene_dialog.get_line_edit().text = _new_file_default
	_new_scene_dialog.title = _dialog_title
	_new_scene_dialog.popup_centered()


## Create a new dialog box scene file
func _new_scene(scene_path: String) -> void:
	SproutyDialogsFileUtils.create_new_scene_file(scene_path, _new_scene_type)
	
	# Set the dialog box scene path
	set_scene_path(scene_path)
	scene_path_changed.emit(scene_path)

	# Open the new scene in the editor
	SproutyDialogsFileUtils.open_scene_in_editor(scene_path, get_tree())


## Check if the scene path is valid
func _check_valid_scene(path: String, print_error: bool = true) -> bool:
	var is_valid = SproutyDialogsFileUtils.check_valid_extension(path, ["*.tscn"]) \
			and FileAccess.file_exists(path)
	
	if is_valid: # Check if the scene inherits from DialogBox class
		var scene = load(path).instantiate()
		match scene_type:
			SceneType.DIALOG_BOX:
				if not scene is DialogBox:
					if print_error:
						printerr("[Sprouty Dialogs] The scene '" + path + "' is not valid."
								+ " The root node must inherit from DialogBox class.")
					is_valid = false
			SceneType.PORTRAIT:
				if not scene is DialogPortrait:
					if print_error:
						printerr("[Sprouty Dialogs] The scene '" + path + "' is not valid."
								+ " The root node must inherit from DialogPortrait class.")
					is_valid = false
		scene.queue_free()
	
	$GoToSceneButton.visible = is_valid
	$NewSceneButton.visible = not is_valid

	return is_valid
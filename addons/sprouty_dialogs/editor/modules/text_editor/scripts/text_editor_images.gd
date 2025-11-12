@tool
extends VBoxContainer

# -----------------------------------------------------------------------------
# Text Editor Images
# -----------------------------------------------------------------------------
## Controller to add images to the text in the text editor.
## Use the [img][/img] tag to apply the image to the text.
# -----------------------------------------------------------------------------

## Text editor reference
@export var text_editor: EditorSproutyDialogsTextEditor

## Image other options bar
@onready var _image_other_options: Control = %ImageOptions
## Image other options expand button
@onready var _image_options_expand_button: Button = %ImageOptionsExpandButton
## Image color sample hex code
@onready var _image_color_sample_hex: RichTextLabel = %ImageColorSample
## Pixels or percent dropdown selector
@onready var _px_or_per_selector: OptionButton = %PixelsOrPercentButton

## Current image width
var _image_width: float = 0.0
## Current image height
var _image_height: float = 0.0
## Image width and height default value
var _size_default: String = "0%"

## Current X region value
var _region_x: float = 0.0
## Current Y region value 
var _region_y: float = 0.0
## Current Width region value
var _region_width: float = 0.0
## Current Height region value
var _region_height: float = 0.0
## Region default value
var _region_default: String = "0.0,0.0,0.0,0.0"


## Show the images options bar
func _on_add_image_pressed() -> void:
	text_editor.change_option_bar(5)
	_on_image_options_expand_toggled(false)


## Show the images options bar
func _on_image_options_expand_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_image_options_expand_button.icon = text_editor.expand_icon
		_image_other_options.show()
	else:
		_image_options_expand_button.icon = text_editor.collapse_icon
		_image_other_options.hide()


## Change the selected image
func _on_image_path_submitted(path: String) -> void:
	# Find the image tags around the cursor
	var tags_pos = text_editor.find_tags_around_cursor("[img", "[/img]")

	if tags_pos.is_empty(): # If there are no image tags, insert a new one
		text_editor.insert_tags_at_cursor_pos("[img]" + path, "[/img]")
		return
	
	# Find the position of the path inside the tags
	var text_input = text_editor.get_text_input()
	var selected_text = text_input.get_selected_text()
	var open_tag_split = selected_text.split("]")

	var open_tag_end = open_tag_split[0].length() + 1
	var close_tag_start = open_tag_end + open_tag_split[1].find("[/img")

	# Update the path start and end position
	tags_pos[1].x = tags_pos[0].x + close_tag_start # End path position
	tags_pos[0].x += open_tag_end # Start path position

	text_input.remove_text(
			tags_pos[0].y, tags_pos[0].x,
			tags_pos[0].y, tags_pos[1].x)
	
	text_input.insert_text(path, tags_pos[0].y, tags_pos[0].x)

	text_input.select(
			tags_pos[0].y, tags_pos[0].x,
			tags_pos[0].y, tags_pos[0].x + path.length())


## Update the image width value
func _on_image_width_value_changed(value: float) -> void:
	var _image_width = snapped(value, 0.1) # Snap the value to the nearest 0.1
	var width = str(_image_width)

	if _px_or_per_selector.selected > 0: # If the selected value is not pixels
		width += "%" # Add the percentage symbol
	
	text_editor.add_attribute_to_tag("img", "width", width, _size_default)

## Update the image height value
func _on_image_height_value_changed(value: float) -> void:
	_image_height = snapped(value, 0.1) # Snap the value to the nearest 0.1
	var height = str(_image_height)

	if _px_or_per_selector.selected > 0: # If the selected value is not pixels
		height += "%" # Add the percentage symbol
	
	text_editor.add_attribute_to_tag("img", "height", height, _size_default)


## Update the image width and height values by pixels or percent
func _on_pixels_or_percent_item_selected(index: int) -> void:
	_on_image_width_value_changed(_image_width)
	_on_image_height_value_changed(_image_height)


## Returns the region attributes as a string
func _get_region_attributes() -> String:
	return (str(_region_x) + "," + str(_region_y) + ","
			+ str(_region_width) + "," + str(_region_height))


## Update the x value of image region
func _on_region_x_value_changed(value: float) -> void:
	_region_x = snapped(value, 0.1)
	text_editor.add_attribute_to_tag("img", "region",
		_get_region_attributes(), _region_default)


## Update the y value of image region
func _on_region_y_value_changed(value: float) -> void:
	_region_y = snapped(value, 0.1)
	text_editor.add_attribute_to_tag("img", "region",
		_get_region_attributes(), _region_default)


## Update the width value of image region
func _on_region_width_value_changed(value: float) -> void:
	_region_width = snapped(value, 0.1)
	text_editor.add_attribute_to_tag("img", "region",
		_get_region_attributes(), _region_default)


## Update the height value of image region
func _on_region_height_value_changed(value: float) -> void:
	_region_height = snapped(value, 0.1)
	text_editor.add_attribute_to_tag("img", "region",
		_get_region_attributes(), _region_default)


## Change the selected image padding
func _on_padding_toggled(toggled_on: bool) -> void:
	text_editor.add_attribute_to_tag("img", "pad", toggled_on, false)


## Change the selected image modulate color
func _on_image_color_changed(color: Color) -> void:
	text_editor.add_attribute_to_tag("img", "color", color.to_html(), "#ffffff")
	_image_color_sample_hex.text = "Hex: #[color=" + color.to_html() + "]" + color.to_html()

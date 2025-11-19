@tool
extends VBoxContainer

# -----------------------------------------------------------------------------
# Alert Controller 
# -----------------------------------------------------------------------------
## Controller to manage alerts in the graph editor.
## The alerts are used to show errors and warnings in the graph editor.
## It provides methods to show, hide, and focus alerts.
# -----------------------------------------------------------------------------

enum AlertType {ERROR, WARNING}

## Templates for error alert
var error_template = preload(
	"res://addons/sprouty_dialogs/editor/modules/graph_editor/alerts/error_alert.tscn"
	)
## Templates for warning alert
var warning_template = preload(
	"res://addons/sprouty_dialogs/editor/modules/graph_editor/alerts/warning_alert.tscn"
	)


func _ready() -> void:
	for child in get_children():
		child.queue_free() # Clean old alerts


## Check if there are some error alerts active
func is_error_alert_active() -> bool:
	for child in get_children():
		if child.alert_type == AlertType.ERROR and child.visible:
			return true
	return false


## Add a new alert and show it
## The type can be AlertType.ERROR (0) or AlertType.WARNING (1)
func show_alert(message: String, alert_type: int) -> EditorSproutyDialogsAlert:
	var alert = null
	match alert_type:
		AlertType.ERROR:
			alert = error_template.instantiate()
		AlertType.WARNING:
			alert = warning_template.instantiate()
	
	add_child(alert)
	alert.show_alert(message)
	return alert


## Hide and destroy a given alert
func hide_alert(alert: EditorSproutyDialogsAlert) -> void:
	if not alert: return
	alert.hide_alert()


## Focus an alert doing an animation
func focus_alert(alert: EditorSproutyDialogsAlert) -> void:
	if not alert: return
	alert._play_focus_animation()

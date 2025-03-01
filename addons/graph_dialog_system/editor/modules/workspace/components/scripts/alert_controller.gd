@tool
extends VBoxContainer

## -----------------------------------------------------------------------------
## Alert Controller 
##
## Controller to manage alerts in the graph editor.
## -----------------------------------------------------------------------------

## Templates for error alert
var error_template = preload(
	"res://addons/graph_dialog_system/editor/modules/workspace/components/error_alert.tscn"
	)
## Templates for warning alert
var warning_template = preload(
	"res://addons/graph_dialog_system/editor/modules/workspace/components/warning_alert.tscn"
	)


func _ready() -> void:
	for child in get_children():
		child.queue_free() # Clean old alerts


## Check if there are some error alerts active
func is_error_alert_active() -> bool:
	for child in get_children():
		if child.alert_type == "ERROR" and child.visible:
			return true
	return false


## Add a new alert and show it
func show_alert(text: String, type: String) -> GDialogsAlert:
	match type:
		"ERROR":
			var alert = error_template.instantiate()
			self.add_child(alert)
			alert.show_alert(text)
			return alert
		"WARNING":
			var alert = warning_template.instantiate()
			self.add_child(alert)
			alert.show_alert(text)
			return alert
		_:
			return null


## Hide and destroy a given alert
func hide_alert(alert: GDialogsAlert) -> void:
	if not alert: return
	alert.hide_alert()


## Focus an alert doing an animation
func focus_alert(alert: GDialogsAlert) -> void:
	if not alert: return
	alert._play_focus_animation()

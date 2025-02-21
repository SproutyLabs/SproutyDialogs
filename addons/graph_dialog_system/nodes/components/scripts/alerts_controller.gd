@tool
extends VBoxContainer

var error_template = preload("res://addons/graph_dialog_system/nodes/components/error_alert.tscn")

func _ready() -> void:
	# Clean old alerts
	for child in get_children():
		child.queue_free()

func is_error_alert_active() -> bool:
	# Check if there are some error alerts active
	for child in get_children():
		if child.alert_type == "ERROR" and child.visible:
			return true
	return false

func show_alert(text : String, type : String) -> GDialogsAlert:
	# Add a new alert and show it
	match type:
		"ERROR":
			var alert = error_template.instantiate()
			self.add_child(alert)
			alert.show_alert(text)
			return alert
		"WARNING":
			return null # TODO
		_:
			return null

func hide_alert(alert : GDialogsAlert) -> void:
	# Hide and destroy a given alert
	alert.hide_alert()

func focus_alert(alert : GDialogsAlert) -> void:
	# Focus an alert doing an animation
	alert._play_focus_animation()

@tool
class_name EditorSproutyDialogsAlert
extends MarginContainer

# -----------------------------------------------------------------------------
# Sprouty Dialogs Alert Component
# -----------------------------------------------------------------------------
## Alert component to display errors and warnings in graph editor.
## It provides methods to show, hide, and focus the alert.
# -----------------------------------------------------------------------------

enum AlertType {ERROR, WARNING}

## Alert type to display
@export var alert_type: AlertType = AlertType.ERROR


func _ready() -> void:
	# Set alert icon based on alert type
	if alert_type == AlertType.ERROR:
		$Panel/Container/Icon.texture = get_theme_icon("Close", "EditorIcons")
	
	# Hide alert outside the view
	position.x = size.x
	visible = false


## Show an alert with the given message.
func show_alert(message: String) -> void:
	%TextLabel.text = message
	visible = true
	_play_show_animation()


## Hide error alert and clean text error
func hide_alert() -> void:
	_play_hide_animation()


# Play animation to show alert
func _play_show_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position:x", 0.0, 0.25) \
			.from(size.x).set_ease(Tween.EASE_IN)


# Play animation to hide alert
func _play_hide_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position:x", size.x, 0.25) \
			.from(0.0).set_ease(Tween.EASE_OUT)
	tween.tween_callback(self.queue_free)


# Play animation to show focus on an alert
func _play_focus_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.1)

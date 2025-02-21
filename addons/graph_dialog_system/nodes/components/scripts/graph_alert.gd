@tool
class_name GDialogsAlert
extends MarginContainer

## ------------------------------------------------------------------
## Handle graph editor alerts
## ------------------------------------------------------------------

@export_enum("ERROR", "WARNING") var alert_type : String

func _ready() -> void:
	# Hide alert outside the view
	position.x = size.x
	visible = false

func show_alert(text : String) -> void:
	# Show error alert with given text error
	%TextLabel.text = text
	visible = true
	_play_show_animation()

func hide_alert() -> void:
	# Hide error alert and clean text error
	_play_hide_animation()

func _play_show_animation() -> void:
	# Play animation to show alert
	var tween = create_tween()
	tween.tween_property(self, "position:x", 0.0, 0.25)\
			.from(size.x).set_ease(Tween.EASE_IN)

func _play_hide_animation() -> void:
	# Play animation to hide alert
	var tween = create_tween()
	tween.tween_property(self, "position:x", size.x, 0.25)\
			.from(0.0).set_ease(Tween.EASE_OUT)
	tween.tween_callback(self.queue_free)

func _play_focus_animation() -> void:
	# Play animation to show focus on an alert
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.1)

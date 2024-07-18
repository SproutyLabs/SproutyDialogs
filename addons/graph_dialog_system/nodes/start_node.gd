@tool
extends GraphNode

func _ready():
	pass

func _on_resized() -> void:
	size.y = 0 # Keep vertical size on resize

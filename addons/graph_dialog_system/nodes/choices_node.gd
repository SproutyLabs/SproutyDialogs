@tool
extends GraphNode

@onready var option_scene : PackedScene = preload("res://addons/graph_dialog_system/nodes/components/option_container.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_add_option_button_pressed():
	# Add a new option to the choices
	var new_option = option_scene.instantiate()
	var option_index = get_child_count() - 2
	
	add_child(new_option, true)
	move_child(new_option, option_index)
	new_option.update_option_index(option_index)
	
	# Add slot to connect the option
	set_slot(option_index, false, 0, Color.WHITE, true, 0, Color.WHITE)
	new_option.option_removed.connect(_on_option_removed)

func _on_option_removed(index : int):
	# Handle options when one is removed
	get_child(index).queue_free() # Delete option
	print("removed: option "+ str(index))
	
	# Update the options indexes
	for child in get_children(false):
		if child is VBoxContainer and child.get_index() > index:
			child.update_option_index(child.get_index() - 1)
			print(child.name)
	
	set_slot(get_child_count() - 3, false, 0, Color.WHITE, false, 0, Color.WHITE)

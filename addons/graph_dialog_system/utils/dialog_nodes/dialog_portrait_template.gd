@tool
extends DialogPortrait


func update_portrait() -> void:
	# This method is called when the portrait is instantiated or changed
	# This is the default behavior of the portrait when is active
	# You can add your own logic here to handle the portrait update
	pass


func on_portrait_entry() -> void:
	# This method is called when the character enters the scene
	# Then the portrait goes to its default behavior (update_portrait is called)
	# You can add your own logic here to handle the portrait when the character enters
	pass


func on_portrait_exit() -> void:
	# This method is called when the character leaves the scene
	# You can add your own logic here to handle the portrait when the character leaves
	pass


func on_portrait_talk() -> void:
	# This method is called when the character starts talking (typing dialog)
	# You can add your own logic here to handle the portrait when the character talks
	pass


func on_portrait_talk_end() -> void:
	# This method is called when the character stops talking (dialog finished)
	# Then the portrait goes to its default behavior (update_portrait is called)
	# You can add your own logic here to handle the portrait when the character stops talking
	pass

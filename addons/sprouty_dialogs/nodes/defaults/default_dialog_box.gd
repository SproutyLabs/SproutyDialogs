@tool
extends DialogBox

# -----------------------------------------------------------------------------
# This is a template for a custom dialog box with a default behavior.
# -----------------------------------------------------------------------------
## This script provides a basic implementation of a dialog box behavior.
## You can override the properties and methods to implement your own logic.
##
## -- NOTE -------------------------------------------------------------
## You should not override other DialogBox methods that are not here,
## because they are necessary to handle the dialog boxes.
## ---------------------------------------------------------------------
# -----------------------------------------------------------------------------


func _on_dialog_box_open() -> void:
	# --------------------------------------------------------------------------
	# This method is called when the dialog box starts.
	# You can add your own logic here to handle the start of the dialog box.
	# (e.g. play an animation to enter to the scene)
	# --------------------------------------------------------------------------
	# In this base case, the dialog box only is shown when it starts
	show()


func _on_dialog_box_close() -> void:
	# --------------------------------------------------------------------------
	# This method is called when the dialog box is closed.
	# You can add your own logic here to handle the closing of the dialog box.
	# (e.g. play an animation to exit the scene)
	# --------------------------------------------------------------------------
	# In this base case, the dialog box only is hidden when closed
	hide()


func _on_options_displayed() -> void:
	# --------------------------------------------------------------------------
	# This method is called when the dialog options are displayed.
	# You can add your own logic here to handle when the options are displayed.
	# (e.g. play an animation to display the options)
	# --------------------------------------------------------------------------
	if options_container:
		options_container.show()


func _on_options_hidden() -> void:
	# --------------------------------------------------------------------------
	# This method is called when the dialog options are hidden.
	# You can add your own logic here to handle when the options are hidden.
	# (e.g. play an animation to hide the options)
	# --------------------------------------------------------------------------
	if options_container:
		options_container.hide()
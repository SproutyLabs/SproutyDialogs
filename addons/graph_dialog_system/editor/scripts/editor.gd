@tool
extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func switch_active_tab(tab : int):
	# Change the selected active tab
	%TabContainer.current_tab = tab

func _on_tab_selected(tab: int):
	# Handle when a tab is selected
	match tab:
		0: # Graph dialog tab
			%FileManager/%CSVFileContainer.visible = true
		1: # Character tab
			%FileManager/%CSVFileContainer.visible = false
		2: # Variable tab
			%FileManager/%CSVFileContainer.visible = false

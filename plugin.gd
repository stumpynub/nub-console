@tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("NubConsole", "res://addons/nub-console/scenes/console.tscn")

func _exit_tree():
	# Clean-up of the plugin goes here.
	pass

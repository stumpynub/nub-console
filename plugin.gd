@tool
extends EditorPlugin

func _enable_plugin():
	add_autoload_singleton("NubConsole", "res://addons/nub-console/scenes/console.tscn")

func _exit_tree():
	remove_autoload_singleton("NubConsole")

tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("StatsOverlay", "CanvasLayer", preload("StatsOverlay.gd"), preload("icon.png"))
	pass
	
func _exit_tree():
	remove_custom_type("StatsOverlay")
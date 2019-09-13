extends Node2D

class_name ArmPointingToMouse2D

func _process(delta):
	look_to_mouse()


func look_to_mouse() -> void:
	look_at(get_global_mouse_position())
	
	if global_position.x < get_global_mouse_position().x:
		set_scale(Vector2(1, 1))
	else:
		set_scale(Vector2(1, -1))
